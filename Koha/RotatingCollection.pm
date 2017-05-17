package Koha::RotatingCollection;

# Copyright Josef Moravec 2016
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
use Koha::Exceptions;
use Koha::Holds;
use Koha::Items;
use Koha::RotatingCollection::Trackings;

use base qw(Koha::Object);

=head1 NAME

Koha::RotatingCollection - Koha Rotating collection Object class

=head1 API

=head2 Class Methods

=cut

=head3 items

=cut

sub items {
    my ( $self ) = @_;
    my $items = Koha::Items->search(
        {
            'collections_trackings.colId' => $self->colId
        },
        {
            join => [ 'collections_trackings' ]
        }
    );

    return $items;
}

=head3 add_item

$collection->add_item( $itemnumber );

throws
    Koha::Exceptions::MissingParameter
    Koha::Exceptions::DuplicateObject
    Koha::Exceptions::ObjectNotFound

=cut

sub add_item {
    my ( $self, $itemnumber ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $itemnumber;

    Koha::Exceptions::DuplicateObject->throw
        if Koha::RotatingCollection::Trackings->search( { itemnumber => $itemnumber } )->count;

    Koha::Exceptions::ObjectNotFound->throw if not Koha::Items->find( $itemnumber );

    my $col_tracking = Koha::RotatingCollection::Tracking->new(
        {
            colId => $self->colId,
            itemnumber => $itemnumber,
        }
    )->store;

    return $col_tracking;
}

=head3 remove_item

$collection->remove_item( $itemnumber )

throws
    Koha::Exceptions::MissingParameter
    Koha::Exceptions::ObjectNotFound

=cut

sub remove_item {
    my ( $self, $itemnumber ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $itemnumber;

    my $collection_tracking = Koha::RotatingCollection::Trackings->find(
        {
            itemnumber => $itemnumber,
            colId      => $self->colId,
        } );

    Koha::Exceptions::ObjectNotFound->throw if not defined $collection_tracking;

    return $collection_tracking->delete;
}

=head3 transfer

$collection->transfer( $branchcode)

throws
    Koha::Exceptions::MissingParameter

=cut

sub transfer {
    my ( $self, $branchcode ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $branchcode;

    $self->colBranchcode( $branchcode )->store;

    my $items = $self->items;
    while ( my $item = $items->next ) {
        my $holds = Koha::Holds->search( {
            itemnumber => $item->itemnumber,
            found      => 'W',
        } );
        C4::Circulation::transferbook( $branchcode, $item->barcode, my $ignore_reserves = 1 ) unless ( $holds->count || $item->get_transfer );
    }
}

=head3 type

=cut

sub _type {
    return 'Collection';
}

=head1 AUTHOR

Josef Moravec <josef.moravec@gmail.com>

=cut

1;
