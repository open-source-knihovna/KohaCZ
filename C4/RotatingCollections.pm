package C4::RotatingCollections;

# $Id: RotatingCollections.pm,v 0.1 2007/04/20 kylemhall

# This package is inteded to keep track of what library
# Items of a certain collection should be at.

# Copyright 2007 Kyle Hall
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Koha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Koha; if not, see <http://www.gnu.org/licenses>.

use Modern::Perl;

use C4::Context;
use C4::Circulation;
use C4::Reserves qw(CheckReserves);
use Koha::Database;

use DBI;

use Data::Dumper;

use vars qw(@ISA @EXPORT);


=head1 NAME

C4::RotatingCollections - Functions for managing rotating collections

=head1 FUNCTIONS

=cut

BEGIN {
    require Exporter;
    @ISA    = qw( Exporter );
    @EXPORT = qw(
      AddItemToCollection
      RemoveItemFromCollection
      TransferCollection
    );
}

=head2 AddItemToCollection

 ( $success, $errorcode, $errormessage ) = AddItemToCollection( $colId, $itemnumber );

Adds an item to a rotating collection.

 Input:
   $colId: Collection to add the item to.
   $itemnumber: Item to be added to the collection
 Output:
   $success: 1 if all database operations were successful, 0 otherwise
   $errorCode: Code for reason of failure, good for translating errors in templates
   $errorMessage: English description of error

=cut

sub AddItemToCollection {
    my ( $colId, $itemnumber ) = @_;

    ## Check for all necessary parameters
    if ( !$colId ) {
        return ( 0, 1, "NO_ID" );
    }
    if ( !$itemnumber ) {
        return ( 0, 2, "NO_ITEM" );
    }

    if ( isItemInThisCollection( $itemnumber, $colId ) ) {
        return ( 0, 2, "IN_COLLECTION" );
    }
    elsif ( isItemInAnyCollection($itemnumber) ) {
        return ( 0, 3, "IN_COLLECTION_OTHER" );
    }

    my $dbh = C4::Context->dbh;

    my $sth;
    $sth = $dbh->prepare("
        INSERT INTO collections_tracking (
            colId,
            itemnumber
        ) VALUES ( ?, ? )
    ");
    $sth->execute( $colId, $itemnumber ) or return ( 0, 3, $sth->errstr() );

    return 1;

}

=head2  RemoveItemFromCollection

 ( $success, $errorcode, $errormessage ) = RemoveItemFromCollection( $colId, $itemnumber );

Removes an item to a collection

 Input:
   $colId: Collection to add the item to.
   $itemnumber: Item to be removed from collection

 Output:
   $success: 1 if all database operations were successful, 0 otherwise
   $errorCode: Code for reason of failure, good for translating errors in templates
   $errorMessage: English description of error

=cut

sub RemoveItemFromCollection {
    my ( $colId, $itemnumber ) = @_;

    ## Check for all necessary parameters
    if ( !$itemnumber ) {
        return ( 0, 2, "NO_ITEM" );
    }

    if ( !isItemInThisCollection( $itemnumber, $colId ) ) {
        return ( 0, 2, "NOT_IN_COLLECTION" );
    }

    my $dbh = C4::Context->dbh;

    my $sth;
    $sth = $dbh->prepare(
        "DELETE FROM collections_tracking
                        WHERE itemnumber = ?"
    );
    $sth->execute($itemnumber) or return ( 0, 3, $sth->errstr() );

    return 1;
}

=head2 TransferCollection

 ( $success, $errorcode, $errormessage ) = TransferCollection( $colId, $colBranchcode );

Transfers a collection to another branch

 Input:
   $colId: id of the collection to be updated
   $colBranchcode: branch where collection is moving to

 Output:
   $success: 1 if all database operations were successful, 0 otherwise
   $errorCode: Code for reason of failure, good for translating errors in templates
   $errorMessage: English description of error

=cut

sub TransferCollection {
    my ( $colId, $colBranchcode ) = @_;

    ## Check for all necessary parameters
    if ( !$colId ) {
        return ( 0, 1, "NO_ID" );
    }
    if ( !$colBranchcode ) {
        return ( 0, 2, "NO_BRANCHCODE" );
    }

    my $dbh = C4::Context->dbh;

    my $sth;
    $sth = $dbh->prepare(
        "UPDATE collections
                        SET 
                        colBranchcode = ? 
                        WHERE colId = ?"
    );
    $sth->execute( $colBranchcode, $colId ) or return ( 0, 4, $sth->errstr() );

    $sth = $dbh->prepare(q{
        SELECT items.itemnumber, items.barcode FROM collections_tracking
        LEFT JOIN items ON collections_tracking.itemnumber = items.itemnumber
        LEFT JOIN issues ON items.itemnumber = issues.itemnumber
        WHERE issues.borrowernumber IS NULL
          AND collections_tracking.colId = ?
    });
    $sth->execute($colId) or return ( 0, 4, $sth->errstr );
    my @results;
    while ( my $item = $sth->fetchrow_hashref ) {
        my ($status) = CheckReserves( $item->{itemnumber} );
        my @transfers = C4::Circulation::GetTransfers( $item->{itemnumber} );
        C4::Circulation::transferbook( $colBranchcode, $item->{barcode}, my $ignore_reserves = 1 ) unless ( $status eq 'Waiting' || @transfers );
    }

    return 1;

}

=head2 isItemInThisCollection

  $inCollection = isItemInThisCollection( $itemnumber, $colId );

=cut

sub isItemInThisCollection {
    my ( $itemnumber, $colId ) = @_;

    my $dbh = C4::Context->dbh;

    my $sth = $dbh->prepare(
"SELECT COUNT(*) as inCollection FROM collections_tracking WHERE itemnumber = ? AND colId = ?"
    );
    $sth->execute( $itemnumber, $colId ) or return (0);

    my $row = $sth->fetchrow_hashref;

    return $$row{'inCollection'};
}

=head2 isItemInAnyCollection

$inCollection = isItemInAnyCollection( $itemnumber );

=cut

sub isItemInAnyCollection {
    my ($itemnumber) = @_;

    my $dbh = C4::Context->dbh;

    my $sth = $dbh->prepare(
        "SELECT itemnumber FROM collections_tracking WHERE itemnumber = ?");
    $sth->execute($itemnumber) or return (0);

    my $row = $sth->fetchrow_hashref;

    $itemnumber = $row->{itemnumber};
    if ($itemnumber) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

__END__

=head1 AUTHOR

Kyle Hall <kylemhall@gmail.com>

=cut
