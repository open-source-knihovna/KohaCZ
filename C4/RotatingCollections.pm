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
use C4::Items;

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
      WasBiblioTransferedBefore
    );
}

=head2 WasBiblioTransferedBefore

  Tests, if a biblio was at least once transfered to given branch

  my $transferedBefore = WasBiblioTransferedBefore( $branchcode, $biblionumber );

=cut

sub WasBiblioTransferedBefore {
    my ($branchcode, $biblionumber ) = @_;
    
    my $dbh = C4::Context->dbh;
    
    my $sth = $dbh->prepare(
        "SELECT branchtransfers.datesent
        FROM branchtransfers
        JOIN items ON branchtransfers.itemnumber = items.itemnumber
        WHERE branchtransfers.tobranch = ? AND items.biblionumber = ?
        ORDER BY branchtransfers.datesent DESC
        LIMIT 1"
    );
    $sth->execute($branchcode, $biblionumber);

    my $row = $sth->fetchrow_hashref;

    if ( defined $row ) {
        return 1;
     } else {
        return 0;
     }
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
