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

package C4::NCIP::LookupItem;

use Modern::Perl;
use C4::NCIP::NcipUtils;

=head1 NAME

C4::NCIP::LookupItem - NCIP module for effective processing of LookupItem NCIP service

=head1 SYNOPSIS

  use C4::NCIP::LookupItem;

=head1 DESCRIPTION

        Info about NCIP and it's services can be found here: http://www.niso.org/workrooms/ncip/resources/

=cut

=head1 METHODS

=head2 lookupItem

        lookupItem($cgiInput)

        Expected input is as e.g. as follows:
        http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=lookup_item&itemId=95&holdQueueLengthDesired&circulationStatusDesired&itemUseRestrictionTypeDesired&notItemInfo
        or
        http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=lookup_item&itemId=95
        http://188.166.14.82:8080/cgi-bin/koha/svc/ncip?service=lookup_item&barcode=956216

        REQUIRED PARAMS:
        Param 'service=lookup_item' tells svc/ncip to forward the query here.
        Param 'itemId=4' specifies itemnumber to look for.
        Param 'barcode=956216' specifies barcode to look for.

        OPTIONAL PARAMS:
        holdQueueLengthDesired specifies to include number of reserves placed on item
        circulationStatusDesired specifies to include circulation statuses of item
        itemUseRestrictionTypeDesired specifies to inlude item use restriction type of item
        notItemInfo specifies to omit item information (normally returned)
=cut

sub lookupItem {
    my ($query) = @_;

    my $itemId  = $query->param('itemId');
    my $barcode = $query->param('barcode');

    unless (defined $itemId) {
        C4::NCIP::NcipUtils::print400($query,
            "itemId nor barcode is specified..\n")
            unless $barcode;

        $itemId = C4::Items::GetItemnumberFromBarcode($barcode);
    }

    my $iteminfo = C4::Items::GetItem($itemId, $barcode, undef);

    C4::NCIP::NcipUtils::print404($query, "Item not found..")
        unless $iteminfo;

    my $bibId = $iteminfo->{'biblioitemnumber'};

    my $result;
    my $desiredSomething = 0;
    if (   defined $query->param('holdQueueLengthDesired')
        or defined $query->param('circulationStatusDesired'))
    {
        $desiredSomething = 1;

        my $holds = C4::Reserves::GetReserveCountFromItemnumber($itemId);

        if (defined $query->param('holdQueueLengthDesired')) {
            $result->{'holdQueueLength'} = $holds;
        }
        if (defined $query->param('circulationStatusDesired')) {
            $result->{'circulationStatus'}
                = C4::NCIP::NcipUtils::parseCirculationStatus($iteminfo,
                $holds);

            $result->{'dueDate'} = $iteminfo->{'datedue'};
        }
    }
    if (defined $query->param('itemUseRestrictionTypeDesired')) {
        my $restrictions
            = C4::NCIP::NcipUtils::parseItemUseRestrictions($iteminfo);
        unless (scalar @{$restrictions} == 0) {
            $result->{'itemUseRestrictions'} = $restrictions;
        }
        $desiredSomething = 1;
    }

    $result->{'itemInfo'} = parseItem($bibId, $itemId, $iteminfo)
        unless $desiredSomething and defined $query->param('notItemInfo');

    C4::NCIP::NcipUtils::printJson($query, $result);
}

=head2 parseItem

	parseItem($biblionumber, $itemnumber, $item)

	Returns info of biblio level & item level

=cut

sub parseItem {
    my ($bibId, $itemId, $item) = @_;

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare("
        SELECT biblioitems.volume,
                biblioitems.number,
                biblioitems.isbn,
                biblioitems.issn,
                biblioitems.publicationyear,
                biblioitems.publishercode,
                biblioitems.pages,
                biblioitems.size,
                biblioitems.place,
                biblioitems.agerestriction,
                biblio.author,
                biblio.title,
                biblio.unititle,
                biblio.notes,
                biblio.serial
        FROM biblioitems
        LEFT JOIN biblio ON biblio.biblionumber = biblioitems.biblionumber
        WHERE biblioitems.biblionumber = ?");
    $sth->execute($bibId);
    my $result = $sth->fetchrow_hashref;

    return 'SQL query failed' unless $result;

    $result->{itemnumber}     = $itemId;
    $result->{biblionumber}   = $bibId;
    $result->{barcode}        = $item->{barcode};
    $result->{location}       = $item->{location};
    $result->{homebranch}     = $item->{homebranch};
    $result->{restricted}     = $item->{restricted};
    $result->{holdingbranch}  = $item->{holdingbranch};
    $result->{itype}          = $item->{itype};
    $result->{copynumber}     = $item->{copynumber};
    $result->{itemcallnumber} = $item->{itemcallnumber};
    $result->{ccode}          = $item->{ccode};

    return C4::NCIP::NcipUtils::clearEmptyKeys($result);
}

1;
