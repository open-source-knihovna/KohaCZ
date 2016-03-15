package Koha::Patron::CheckPrevIssue;

# This file is part of Koha.
#
# Copyright 2014 PTFS Europe
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

use parent qw( Exporter );

our @EXPORT = qw(
        WantsCheckPrevIssue
        CheckPrevIssue
);

=head1 Koha::Patron::CheckPrevIssue

Koha::Patron::Debarments - Manage Previous Issue preferences & searches.

=head2 WantsCheckPrevIssue

    ($CheckPrevIssueOverride) = WantsCheckPrevIssue( $borrower );

Returns 'yes', 'no' or 'inherit' depending on whether the patron or
patron category should be reminded when items to be loaned have
already been loaned to this borrower.

=cut

sub WantsCheckPrevIssue {
    my ( $borrower ) = @_;
    my $CheckPrevIssueByBrw = $borrower->{checkprevissue};
    if ( $CheckPrevIssueByBrw eq 'inherit' ) {
        return _WantsCheckPrevIssueByCat( $borrower->{borrowernumber} );
    } else {
        return $CheckPrevIssueByBrw;
    }
}

=head2 _WantsCheckPrevIssueByCat

    ($CheckPrevIssueByCatOverride) = _WantsCheckPrevIssueByCat( $borrowernumber );

Returns 'yes', 'no' or 'inherit' depending on whether the patron
in this category should be reminded when items to be loaned have already been
loaned to this borrower.

=cut

sub _WantsCheckPrevIssueByCat {
    my ( $borrowernumber ) = @_;
    my $dbh = C4::Context->dbh;
    my $query = '
SELECT categories.checkprevissue
FROM borrowers
LEFT JOIN categories ON borrowers.categorycode = categories.categorycode
WHERE borrowers.borrowernumber = ?
';
    my $sth;
    if ($borrowernumber) {
        $sth = $dbh->prepare($query);
        $sth->execute($borrowernumber);
    } else {
        return;
    }
    return ${$sth->fetchrow_arrayref()}[0];
}

=head2 IsSerialIssue

    ($IsSerial) = IsSerialIssue( $frameworkcode );

Return 1 if $frameworkcode is a serial one, 0 otherwise.

=cut

sub IsSerialIssue {
    my ( $frameworkcode ) = @_;
    my $dbh   = C4::Context->dbh;
    my @codes = split('\|', (C4::Context->preference('CheckPrevIssueSerialFrameworks') ? C4::Context->preference('CheckPrevIssueSerialFrameworks') : 'PE'));
    foreach my $code ( @codes ) {
        if ($code eq $frameworkcode) {
            return 1;
        }
    }
    return 0;
}

=head2 CheckPrevIssue

    ($PrevIssue) = CheckPrevIssue( $borrowernumber, $biblionumber );

Return 1 if $BIBLIONUMBER has previously been issued to
$BORROWERNUMBER, 0 otherwise.

=cut

sub CheckPrevIssue {
    my ( $borrowernumber, $biblionumber, $itemnumber ) = @_;
    my $dbh       = C4::Context->dbh;
    my $previssue = 0;
    my $frameworkcode = '';
    my $previssuedate = '';

    my $query_biblioinfo = 'select frameworkcode from biblio where biblionumber=?';
    my $sth_biblioinfo = $dbh->prepare($query_biblioinfo);
    $sth_biblioinfo->execute($biblionumber);

    my @biblioinfo = $sth_biblioinfo->fetchrow_array();
    $frameworkcode = $biblioinfo[0];

    my $query_issues = 'select issuedate from old_issues where borrowernumber=? and itemnumber=? order by issuedate desc limit 1';
    my $sth_issues   = $dbh->prepare($query_issues);

    if ( IsSerialIssue($frameworkcode) ) {
        $sth_issues->execute( $borrowernumber, $itemnumber );
        while ( my @matches = $sth_issues->fetchrow_array() ) {
                $previssue = 1;
                $previssuedate = $matches[0];
        }
    } else {
        my $query_items = 'select itemnumber from items where biblionumber=?';
        my $sth_items = $dbh->prepare($query_items);
        $sth_items->execute($biblionumber);

        while ( my @row = $sth_items->fetchrow_array() ) {
            $sth_issues->execute( $borrowernumber, $row[0] );
            while ( my @matches = $sth_issues->fetchrow_array() ) {
                if ( $matches[0] ) {
                    $previssue = 1;
                    $previssuedate = $matches[0];
                    last;
                }
            }
            last if $previssue;
        }
    }
    return $previssue, $previssuedate;
}

1;

=head2 AUTHOR

Alex Sassmannshausen <alex.sassmannshausen@ptfs-europe.com>

=cut

