package Koha::Item;

# Copyright ByWater Solutions 2014
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

use Modern::Perl;

use Carp;

use Koha::Database;

use Koha::Item::Transfer;
use C4::Context;
use Koha::Holds;
use Koha::Issues;
use Koha::Item::Availability;
use Koha::ItemTypes;
use Koha::Patrons;
use Koha::Libraries;

use base qw(Koha::Object);

=head1 NAME

Koha::Item - Koha Item object class

=head1 API

=head2 Class Methods

=cut

=head3 availabilities

my $available = $item->availabilities();

Gets different availability types, generally, without considering patron status.

Returns HASH containing Koha::Item::Availability objects for each availability
type. Currently implemented availabilities are:
    * hold
    * checkout
    * local_use
    * onsite_checkout

=cut

sub availabilities {
    my ( $self, $params ) = @_;

    my $availabilities; # HASH containing different types of availabilities
    my $availability = Koha::Item::Availability->new->set_available;

    $availability->set_unavailable("withdrawn") if $self->withdrawn;
    $availability->set_unavailable("itemlost") if $self->itemlost;
    $availability->set_unavailable("restricted") if $self->restricted;

    if ($self->damaged) {
        if (C4::Context->preference('AllowHoldsOnDamagedItems')) {
            $availability->add_description("damaged");
        } else {
            $availability->set_unavailable("damaged");
        }
    }

    my $itemtype;
    if (C4::Context->preference('item-level_itypes')) {
        $itemtype = Koha::ItemTypes->find( $self->itype );
    } else {
        my $biblioitem = Koha::Biblioitems->find( $self->biblioitemnumber );
        $itemtype = Koha::ItemTypes->find( $biblioitem->itemype );
    }

    if ($self->notforloan > 0 || $itemtype && $itemtype->notforloan) {
        $availability->set_unavailable("notforloan");
    } elsif ($self->notforloan < 0) {
        $availability->set_unavailable("ordered");
    }

    # Hold
    $availabilities->{'hold'} = $availability->clone;

    # Checkout
    if ($self->onloan) {
        my $issue = Koha::Issues->search({ itemnumber => $self->itemnumber })->next;
        $availability->set_unavailable("onloan", $issue->date_due) if $issue;
    }

    if (Koha::Holds->search( [
            { itemnumber => $self->itemnumber },
            { found => [ '=', 'W', 'T' ] }
            ])->count()) {
        $availability->set_unavailable("reserved");
    }

    $availabilities->{'checkout'} = $availability->clone;

    # Local Use,
    if (grep(/^notforloan$/, @{$availability->{description}})
        && @{$availability->{description}} == 1) {
        $availabilities->{'local_use'} = $availability->clone->set_available
                                            ->del_description("notforloan");
    } else {
        $availabilities->{'local_use'} = $availability->clone
                                            ->del_description("notforloan");
    }

    # On-site checkout
    if (!C4::Context->preference('OnSiteCheckouts')) {
        $availabilities->{'onsite_checkout'}
        = Koha::Item::Availability->new
        ->set_unavailable("onsite_checkouts_disabled");
    } else {
        $availabilities->{'onsite_checkout'}
        = $availabilities->{'local_use'}->clone;
    }

    return $availabilities;
}

=head3 availability_for_checkout

my $available = $item->availability_for_checkout();

Gets checkout availability of the item. This subroutine does not check patron
status, instead the purpose is to check general availability for this item.

Returns Koha::Item::Availability object.

=cut

sub availability_for_checkout {
    my ( $self ) = @_;

    return $self->availabilities->{'checkout'};
}

=head3 availability_for_local_use

my $available = $item->availability_for_local_use();

Gets local use availability of the item.

Returns Koha::Item::Availability object.

=cut

sub availability_for_local_use {
    my ( $self ) = @_;

    return $self->availabilities->{'local_use'};
}

=head3 availability_for_onsite_checkout

my $available = $item->availability_for_onsite_checkout();

Gets on-site checkout availability of the item.

Returns Koha::Item::Availability object.

=cut

sub availability_for_onsite_checkout {
    my ( $self ) = @_;

    return $self->availabilities->{'onsite_checkout'};
}

=head3 availability_for_reserve

my $available = $item->availability_for_reserve();

Gets reserve availability of the item. This subroutine does not check patron
status, instead the purpose is to check general availability for this item.

Returns Koha::Item::Availability object.

=cut

sub availability_for_reserve {
    my ( $self ) = @_;

    return $self->availabilities->{'hold'};
}

=head3 effective_itemtype

Returns the itemtype for the item based on whether item level itemtypes are set or not.

=cut

sub effective_itemtype {
    my ( $self ) = @_;

    return $self->_result()->effective_itemtype();
}

=head3 hold_queue_length

=cut

sub hold_queue_length {
    my ( $self ) = @_;

    my $reserves = Koha::Holds->search({ itemnumber => $self->itemnumber });
    return $reserves->count() if $reserves;
    return 0;
}

=head3 home_branch

=cut

sub home_branch {
    my ($self) = @_;

    $self->{_home_branch} ||= Koha::Libraries->find( $self->homebranch() );

    return $self->{_home_branch};
}

=head3 holding_branch

=cut

sub holding_branch {
    my ($self) = @_;

    $self->{_holding_branch} ||= Koha::Libraries->find( $self->holdingbranch() );

    return $self->{_holding_branch};
}

=head3 get_transfer

my $transfer = $item->get_transfer;

Return the transfer if the item is in transit or undef

=cut

sub get_transfer {
    my ( $self ) = @_;
    my $transfer_rs = $self->_result->branchtransfers->search({ datearrived => undef })->first;
    return unless $transfer_rs;
    return Koha::Item::Transfer->_new_from_dbic( $transfer_rs );
}

=head3 last_returned_by

Gets and sets the last borrower to return an item.

Accepts and returns Koha::Patron objects

$item->last_returned_by( $borrowernumber );

$last_returned_by = $item->last_returned_by();

=cut

sub last_returned_by {
    my ( $self, $borrower ) = @_;

    my $items_last_returned_by_rs = Koha::Database->new()->schema()->resultset('ItemsLastBorrower');

    if ($borrower) {
        return $items_last_returned_by_rs->update_or_create(
            { borrowernumber => $borrower->borrowernumber, itemnumber => $self->id } );
    }
    else {
        unless ( $self->{_last_returned_by} ) {
            my $result = $items_last_returned_by_rs->single( { itemnumber => $self->id } );
            if ($result) {
                $self->{_last_returned_by} = Koha::Patrons->find( $result->get_column('borrowernumber') );
            }
        }

        return $self->{_last_returned_by};
    }
}

=head3 type

=cut

sub _type {
    return 'Item';
}

=head1 AUTHOR

Kyle M Hall <kyle@bywatersolutions.com>

=cut

1;
