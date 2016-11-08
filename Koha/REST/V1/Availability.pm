package Koha::REST::V1::Availability;

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

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Koha::Holds;
use Koha::Items;

sub items {
    my ($c, $args, $cb) = @_;

    my @items;
    if ($args->{'itemnumber'}) {
        push @items, _item_availability($args->{'itemnumber'});
    }
    if ($args->{'biblionumber'}) {
        my $found_items = Koha::Items->search({ biblionumber => {
                            '=', \@{$args->{'biblionumber'}}
                            } });

        push @items, _item_availability($found_items);
    }

    return $c->$cb({ error => "Item(s) not found"}, 404) unless scalar @items;
    return $c->$cb([ @items ], 200);
}

sub _item_availability {
    my ($items) = @_;

    if (ref($items) eq 'Koha::Items') {
        $items = $items->as_list;
    }

    my @item_availabilities;
    foreach my $item (@$items) {
        unless (ref($item) eq 'Koha::Item') {
            $item = Koha::Items->find($item);
            next unless $item;
        }

        my $availabilities = _swaggerize_availabilities($item->availabilities);

        my $holds;
        $holds->{'hold_queue_length'} = $item->hold_queue_length;

        my $iteminfo = {
            itemnumber => $item->itemnumber,
            barcode => $item->barcode,
            biblionumber => $item->biblionumber,
            biblioitemnumber => $item->biblioitemnumber,
            enumchron => $item->enumchron,
            holdingbranch => $item->holdingbranch,
            homebranch => $item->homebranch,
            location => $item->location,
            itemcallnumber => $item->itemcallnumber,
            itemnotes => $item->itemnotes,
        };

        # merge availability, hold information and item information
        push @item_availabilities, { %{$availabilities}, %{$holds}, %{$iteminfo} };
    }

    return @item_availabilities;
}

sub _swaggerize_availabilities {
    my ($availabilities) = @_;

    $availabilities->use_stored_values(1);
    my $avail_hash = {
        hold => $availabilities->hold,
        checkout => $availabilities->issue,
        local_use => $availabilities->local_use,
        onsite_checkout => $availabilities->onsite_checkout,
    };

    foreach my $availability (keys $avail_hash) {
        delete $avail_hash->{$availability}->{availability_needs_confirmation};
        $avail_hash->{$availability}->available(
        $avail_hash->{$availability}->available
                             ? Mojo::JSON->true
                             : Mojo::JSON->false);
        $avail_hash->{$availability} = { %{$avail_hash->{$availability}} };
    }

    return $avail_hash;
}

1;
