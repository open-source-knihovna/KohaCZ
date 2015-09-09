#!/usr/bin/perl

# Copyright 2014 ByWater Solutions
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

package C4::NCIP::RenewItem;

use Modern::Perl;

use JSON qw(to_json);

=head1 NAME

C4::NCIP::RenewItem - NCIP module for effective processing of RenewItem NCIP service

=head1 SYNOPSIS

  use C4::NCIP::RenewItem;

=head1 DESCRIPTION

        Info about NCIP and it's services can be found here: http://www.niso.org/workrooms/ncip/resources/

=cut

=head1 METHODS

=head2 renewItem

        renewItem($cgiInput)

        Expected input is as e.g. as follows:
	http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=renew_item&desiredDateDue=20/04/2015&itemId=382&userId=3

        REQUIRED PARAMS:
        Param 'service=renew_item' tells svc/ncip to forward the query here.
        Param 'userId=3' specifies borrowernumber as current borrower of Renewal item.
        Param 'itemId=4' specifies itemnumber to place Renewal on.

        OPTIONAL PARAMS:
	Param 'desiredDateDue=20/04/2015' specifies when would user like to have new DateDue - it is checked against Koha's default RenewalDate & if it is bigger than that, Koha's default RenewalDate is used instead
=cut

sub renewItem {
    my $query  = shift;
    my $itemId = $query->param('itemId');
    my $userId = $query->param('userId');
    my $branch = $query->param('branch') || C4::Context->userenv->{'branch'};
    my $biblio = C4::Biblio::GetBiblioFromItemNumber($itemId);

    unless ($itemId) {
        print $query->header(
            -type   => 'text/plain',
            -status => '400 Bad Request'
        );
        print "itemId is undefined..";
        exit 0;
    }

    unless ($userId) {
        print $query->header(
            -type   => 'text/plain',
            -status => '400 Bad Request'
        );
        print "userId is undefined..";
        exit 0;
    }

    my $dateDue = $query->param('desiredDateDue');
    if ($dateDue) {    # Need to restrict maximal DateDue ..
        my $dbh = C4::Context->dbh;
        # Find the issues record for this book
        my $sth = $dbh->prepare(
            "SELECT branchcode FROM issues WHERE itemnumber = ?");
        $sth->execute($itemId);
        my $issueBranchCode = $sth->fetchrow_array;
        unless ($issueBranchCode) {
            print $query->header(
                -type   => 'text/plain',
                -status => '404 Not Found'
            );
            print 'Checkout wasn\'t found .. Nothing to renew..';
            exit 0;
        }

        my $itemtype
            = (C4::Context->preference('item-level_itypes'))
            ? $biblio->{'itype'}
            : $biblio->{'itemtype'};

        my $now = DateTime->now(time_zone => C4::Context->tz());
        my $borrower = C4::Members::GetMember(borrowernumber => $userId);
        unless ($borrower) {
            print $query->header(
                -type   => 'text/plain',
                -status => '404 Not Found'
            );
            print 'User wasn\'t found ..';
            exit 0;
        }

        my $maxDateDue
            = C4::Circulation::CalcDateDue($now, $itemtype, $issueBranchCode,
            $borrower, 'is a renewal');

        $dateDue = Koha::DateUtils::dt_from_string($dateDue);
        $dateDue->set_hour(23);
        $dateDue->set_minute(59);
        if ($dateDue > $maxDateDue || $dateDue < $now) {
            $dateDue = $maxDateDue;    # Here is the restriction done ..
        }
    }
    my ($okay, $error)
        = C4::Circulation::CanBookBeRenewed($userId, $itemId, '0');

    C4::NCIP::NcipUtils::print409($query, $error) unless $okay;

    $dateDue
        = C4::Circulation::AddRenewal($userId, $itemId, $branch, $dateDue);

    my $result;
    $result->{'itemId'}     = $itemId;
    $result->{'userId'}     = $userId;
    $result->{'branchcode'} = $branch;

    $result->{'dateDue'}
        = Koha::DateUtils::output_pref({dt => $dateDue, as_due_date => 1});

    C4::NCIP::NcipUtils::printJson($query, $result);
}

1;
