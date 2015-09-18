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

package C4::NCIP::RequestItem;

use Modern::Perl;

=head1 NAME

C4::NCIP::RequestItem - NCIP module for effective processing of RequestItem NCIP service

=head1 SYNOPSIS

  use C4::NCIP::RequestItem;

=head1 DESCRIPTION

	Info about NCIP and it's services can be found here: http://www.niso.org/workrooms/ncip/resources/

=cut

=head1 METHODS

=head2 requestItem

	requestItem($cgiInput)

	Expected input is as e.g. as follows:

	http://KohaIntranet:8080/cgi-bin/koha/svc/ncip?service=request_item&requestType=Hold&userId=3&itemid=4&pickupExpiryDate=28/03/2015&pickupLocation=DOSP
	or
	http://KohaIntranet:8080/cgi-bin/koha/svc/ncip?service=request_item&userId=3&bibId=7


	REQUIRED PARAMS:
	Param 'service=request_item' tells svc/ncip to forward the query here.
	Param 'userId=3' specifies borrowernumber to place Reserve to.
	Param 'itemId=4' specifies itemnumber to place Reserve on.
		This param can be replaced with 'barcode=1103246'. But still one of these is required.
		Or with 'bibId=3' - then it is Bibliographic Level Hold.

	OPTIONAL PARAMS:
	Param 'requestType=Hold' can be either 'Hold' or 'Loan'.
	Param 'pickupExpiryDate=28/06/2015' tells until what date is user interested into specified item.
	Param 'pickuplocation=DOSP' specifies which branch is user expecting pickup at.

=cut

sub requestItem {
    my $query  = shift;
    my $userId = $query->param('userId');

    C4::NCIP::NcipUtils::print400($query, "Param userId is undefined..")
        unless $userId;

    my $bibId   = $query->param('bibId');
    my $itemId  = $query->param('itemId');
    my $barcode = $query->param('barcode');

    C4::NCIP::NcipUtils::print400($query,
        "Cannot process both bibId & itemId/barcode .. you have to choose only one"
    ) if $bibId and ($itemId or $barcode);

    my $itemLevelHold = 1;
    unless ($itemId) {
        if ($bibId) {
            my $canBeReserved
                = C4::Reserves::CanBookBeReserved($userId, $bibId);

            print409($query, "Book cannot be reserved.. $canBeReserved")
                unless ($canBeReserved eq 'OK');

            $itemLevelHold = 0;
        } else {
            C4::NCIP::NcipUtils::print400($query,
                "Param bibId neither any of itemId and barcode is undefined")
                unless $barcode;

            $itemId = C4::Items::GetItemnumberFromBarcode($barcode);
        }
    }

    if ($itemLevelHold) {
        my $canBeReserved = C4::Reserves::CanItemBeReserved($userId, $itemId);

        C4::NCIP::NcipUtils::print409($query,
            "Item cannot be reserved.. $canBeReserved")
            unless $canBeReserved eq 'OK';

        $bibId = C4::Biblio::GetBiblionumberFromItemnumber($itemId);
    }

# RequestType specifies if user wants the book now or doesn't mind to get into queue
    my $requestType = $query->param('requestType');

    if ($requestType) {
        C4::NCIP::NcipUtils::print400($query,
            "Param requestType not recognized.. Can be \'Loan\' or \'Hold\'")
            if (not $requestType =~ /^Loan$|^Hold$/);
    } else {
        $requestType = 'Hold';
    }

    # Process rank & whether user hasn't requested this item yet ..
    my $reserves = C4::Reserves::GetReservesFromBiblionumber(
        {biblionumber => $bibId, itemnumber => $itemId, all_dates => 1});

    foreach my $res (@$reserves) {
        C4::NCIP::NcipUtils::print409($query,
            "User already has item requested")
            if $res->{borrowernumber} eq $userId;
    }

    my $rank = scalar(@$reserves);

    C4::NCIP::NcipUtils::print409($query,
        "Loan not possible  .. holdqueuelength exists")
        if $requestType ne 'Hold' and $rank != 0;

    my $now = DateTime->now(time_zone => C4::Context->tz());

    my $expirationdate
        = Koha::DateUtils::dt_from_string($query->param('pickupExpiryDate'));
    $expirationdate
        = $expirationdate < $now ? undef : $query->param('pickupExpiryDate');

    my $startdate = Koha::DateUtils::dt_from_string(
        $query->param('earliestDateNeeded'));
    $startdate
        = $startdate < $now ? undef : $query->param('earliestDateNeeded');

    my $notes = $query->param('notes') || 'Placed by svc/ncip';
    my $pickupLocation = $query->param('pickupLocation')
        || C4::Context->userenv->{'branch'};

    my $branchExists = C4::Branch::GetBranchName($pickupLocation);
    C4::NCIP::NcipUtils::print409($query,
        "Specified pickup location doesn't exist")
        unless $branchExists;

    if ($itemLevelHold) {
        placeHold(
            $query,          $bibId,     $itemId,         $userId,
            $pickupLocation, $startdate, $expirationdate, $notes,
            ++$rank,         undef
        );
    } else {
        placeHold(
            $query,          $bibId,     undef,           $userId,
            $pickupLocation, $startdate, $expirationdate, $notes,
            ++$rank,         'any'
        );
    }
}

=head2 placeHold

	placeHold($inputCGI, $biblionumber, $itemnumber, $borrowernumber, $pickup, $startdate, $expirationdate, $notes, $rank, $requesttype)

=cut

sub placeHold {
    my ($query,  $bibId,     $itemId,         $userId,
        $branch, $startdate, $expirationdate, $notes,
        $rank,   $request
    ) = @_;

    my $found;

    my $userExists = C4::Members::GetBorrowerCategorycode($userId);

    C4::NCIP::NcipUtils::print404($query, "User not found..")
        unless $userExists;

    my $reserveId = C4::Reserves::AddReserve(
        $branch, $userId, $bibId,     'a',
        undef,   $rank,   $startdate, $expirationdate,
        $notes,  undef,   $itemId,    $found
    );

    my $results;

    $results->{'status'}    = 'reserved';
    $results->{'bibId'}     = $bibId;
    $results->{'userId'}    = $userId;
    $results->{'requestId'} = $reserveId;

    $results->{'itemId'} = $itemId if $itemId;

    C4::NCIP::NcipUtils::printJson($query, $results);
}

1;
