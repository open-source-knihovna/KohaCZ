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

package C4::NCIP::CancelRequestItem;

use Modern::Perl;

=head1 NAME

C4::NCIP::CancelRequestItem - NCIP module for effective processing of CancelRequestItem NCIP service

=head1 SYNOPSIS

  use C4::NCIP::CancelRequestItem;

=head1 DESCRIPTION

        Info about NCIP and it's services can be found here: http://www.niso.org/workrooms/ncip/resources/

=cut

=head1 METHODS

=head2 cancelRequestItem

        cancelRequestItem($cgiInput)

        Expected input is as e.g. as follows:

	http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=cancel_request_item&requestId=89&userId=4
        or
	http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=cancel_request_item&itemId=95&userId=3

        REQUIRED PARAMS:
        Param 'service=cancel_request_item' tells svc/ncip to forward the query here.
        Param 'userId=3' specifies borrowernumber whos request is being cancelled.
        Param 'itemId=4' specifies itemnumber to cancel.
	Param 'requestId=89' specifies request to cancel.

=cut

sub cancelRequestItem {
    my ($query)   = @_;
    my $userId    = $query->param('userId');
    my $itemId    = $query->param('itemId');
    my $requestId = $query->param('requestId');
    my ($result, $reserve);
    if (defined $userId and defined $itemId) {
        $reserve
            = C4::Reserves::GetReserveFromBorrowernumberAndItemnumber($userId,
            $itemId);

    } elsif (defined $userId and defined $requestId) {
        $reserve = C4::Reserves::GetReserve($requestId);
    } else {
        C4::NCIP::NcipUtils::print400($query,
            'You have to specify either both \'userId\' & \'itemId\' or both \'userId\' & \'requestId\'..'
        );
# It's a shame schema allow RequestItem with BibId & doesn't allow CancelRequestItem with BibId .. (NCIP Initiatior needs to LookupUser with RequestedItemsDesired -> parse requestId of bibId)
#
# Schema definition of CancelRequestItem:
# <xs:element name="CancelRequestItem"><xs:complexType><xs:sequence><xs:element ref="InitiationHeader" minOccurs="0"/><xs:element ref="MandatedAction" minOccurs="0"/><xs:choice><xs:element ref="UserId"/><xs:element ref="AuthenticationInput" maxOccurs="unbounded"/></xs:choice><xs:choice><xs:element ref="ItemId"/><xs:sequence><xs:element ref="RequestId"/><xs:element ref="ItemId" minOccurs="0"/></xs:sequence></xs:choice><xs:element ref="RequestType"/><xs:element ref="RequestScopeType" minOccurs="0"/><xs:element ref="AcknowledgedFeeAmount" minOccurs="0"/><xs:element ref="PaidFeeAmount" minOccurs="0"/><xs:element ref="ItemElementType" minOccurs="0" maxOccurs="unbounded"/><xs:element ref="UserElementType" minOccurs="0" maxOccurs="unbounded"/><xs:element ref="Ext" minOccurs="0"/></xs:sequence></xs:complexType></xs:element>
#
# Source: http://www.niso.org/schemas/ncip/v2_02/ncip_v2_02.xsd
    }

    C4::NCIP::NcipUtils::print404($query, "Request not found..")
        unless $reserve;

    C4::NCIP::NcipUtils::print403($query,
        'Request doesn\'t belong to this patron ..')
        unless $reserve->{'borrowernumber'} eq $userId;

    C4::Reserves::CancelReserve($reserve);

    $result->{'userId'}    = $reserve->{borrowernumber};
    $result->{'itemId'}    = $reserve->{itemnumber};
    $result->{'requestId'} = $reserve->{reserve_id};
    $result->{'status'}    = 'cancelled';

    C4::NCIP::NcipUtils::printJson($query, $result);
}

1;
