package Koha::RotatingCollection;

# Copyright Josef Moravec 2017
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

use C4::Context;

use Koha::Database;
use Koha::DateUtils;
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

=head3 new

    $collection = Koha::RotatingCollection->new();

    This sub automatically adds date of creation and librarian who created collection if it is not present in params.

=cut

sub new {
    my ($class, $params) = @_;
    $params->{createdOn} //= output_pref({ dt => dt_from_string, dateformat => 'iso', dateonly => 1 });
    $params->{createdBy} = undef;
    $params->{createdBy} = C4::Context->userenv->{number} if defined C4::Context->userenv;

    return $class->SUPER::new($params);
}

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

=head3 untransferred_items

my $untransferred_items = $collection->untransferred_items;

Return all items which are not transferred yet

=cut

sub untransferred_items {
    my ( $self ) = @_;

    my $items = Koha::Items->search(
        {
            'collections_trackings.colId' => $self->colId,
            'branchtransfers.branchtransfer_id' => undef,
        },
        {
            join => [ 'collections_trackings', 'branchtransfers' ]
        }
    );

    return $items;
}

=head3 add_item

$collection->add_item( $item_object );

throws
    Koha::Exceptions::MissingParameter
    Koha::Exceptions::DuplicateObject
    Koha::Exceptions::ObjectNotFound

=cut

sub add_item {
    my ( $self, $item ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $item;

    Koha::Exceptions::ObjectNotFound->throw if ref($item) ne 'Koha::Item';

    Koha::Exceptions::DuplicateObject->throw
        if Koha::RotatingCollection::Trackings->search( { itemnumber => $item->itemnumber } )->count;

    my $col_tracking = Koha::RotatingCollection::Tracking->new(
        {
            colId => $self->colId,
            itemnumber => $item->itemnumber,
        }
    )->store;

    return $col_tracking;
}

=head3 remove_item

$collection->remove_item( $item_object )

throws
    Koha::Exceptions::MissingParameter
    Koha::Exceptions::ObjectNotFound

=cut

sub remove_item {
    my ( $self, $item ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $item;

    Koha::Exceptions::ObjectNotFound->throw if ref($item) ne 'Koha::Item';

    my $collection_tracking = Koha::RotatingCollection::Trackings->find(
        {
            itemnumber => $item->itemnumber,
            colId      => $self->colId,
        } );

    Koha::Exceptions::ObjectNotFound->throw if not defined $collection_tracking;

    return $collection_tracking->delete;
}

=head3 transfer

$collection->transfer( $library_object )

throws
    Koha::Exceptions::MissingParameter
    Koha::Exceptions::ObjectNotFound

=cut

sub transfer {
    my ( $self, $library ) = @_;

    Koha::Exceptions::MissingParameter->throw if not defined $library;

    Koha::Exceptions::ObjectNotFound->throw if ref($library) ne 'Koha::Library';

    $self->colBranchcode( $library->branchcode );
    $self->lastTransferredOn( output_pref({ dt => dt_from_string, dateformat => 'iso', dateonly => 1 }) );
    $self->store;

    my $from;
    $from = C4::Context->userenv->{'branch'} if C4::Context->userenv;

    my $items = $self->items;
    while ( my $item = $items->next ) {
        my $holds = Koha::Holds->search( {
            itemnumber => $item->itemnumber,
            found      => 'W',
        } );


        # If no user context is defined the default from library for transfer will be the 'holding' one
        $from = $item->holdingbranch if not defined $from;
        unless ($holds->count || $item->get_transfer) {
            my $transfer = Koha::Item::Transfer->new( {
                frombranch => $from,
                tobranch => $library->branchcode,
                itemnumber => $item->itemnumber,
                datesent => output_pref({ dt => dt_from_string, dateformat => 'iso', dateonly => 1 }),
                comments => $self->colTitle,
            } )->store;
            $item->holdingbranch( $library->branchcode )->store;
        }
    }
}

=head3 creator

    $creator = $collection->creator

    return creator (Koha::Patron object) of this collection

=cut

sub creator {
    my ( $self ) = @_;

    return unless $self->createdBy;

    my $patron = Koha::Patrons->find( $self->createdBy );

    return $patron;
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
