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

package C4::NCIP::LookupRequest;

use Modern::Perl;

=head1 NAME

C4::NCIP::LookupRequest - NCIP module for effective processing of LookupRequest NCIP service

=head1 SYNOPSIS

  use C4::NCIP::LookupRequest;

=head1 DESCRIPTION

        Info about NCIP and it's services can be found here: http://www.niso.org/workrooms/ncip/resources/

=cut

=head1 METHODS

=head2 lookupRequest

        lookupRequest($cgiInput)

        Expected input is as e.g. as follows:
	http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=lookup_request&userId=1&itemId=111
        or
	http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=lookup_request&requestId=83

        REQUIRED PARAMS:
        Param 'service=lookup_request' tells svc/ncip to forward the query here.
	Either:
	        Param 'userId=3' specifies borrowernumber to look for.
		Param 'itemId=1' specifies itemnumber to look for.
	Or:
		Param 'requestId=83' specifies number of request to look for-
=cut

sub lookupRequest {
    my ($query) = @_;
    my $requestId = $query->param('requestId');

    my $result;
    if (defined $requestId) {
        $result = C4::Reserves::GetReserve($requestId);
    } else {
        my $userId = $query->param('userId');
        my $itemId = $query->param('itemId');

        C4::NCIP::NcipUtils::print400($query,
            'You have to specify \'requestId\' or both \'userId\' & \'itemId\'..'
        ) unless (defined $userId and defined $itemId);

        $result
            = C4::Reserves::GetReserveFromBorrowernumberAndItemnumber($userId,
            $itemId);
    }

    C4::NCIP::NcipUtils::print404($query, "Request not found..")
        unless $result;

    my $onLoanUntil = parseDateDue($result->{'itemnumber'});
    $result->{'onloanuntil'} = $onLoanUntil if $onLoanUntil;

    C4::NCIP::NcipUtils::clearEmptyKeys($result);

    C4::NCIP::NcipUtils::printJson($query, $result);
}

=head2 parseDateDue

	parseDateDue($itemnumber)

	Returns item's date_due if exists .. else undef

=cut

sub parseDateDue {

    my ($itemId) = @_;
    my $dbh      = C4::Context->dbh;
    my $sth      = $dbh->prepare("
        SELECT date_due
        FROM issues
        WHERE itemnumber = ?");
    $sth->execute($itemId);

    my $issue = $sth->fetchrow_hashref;
    return unless $issue;

    return $issue->{date_due};
}
1;
