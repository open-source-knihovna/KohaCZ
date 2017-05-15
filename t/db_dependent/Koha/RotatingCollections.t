#!/usr/bin/perl

# This file is part of Koha.
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

use Test::More tests => 2;
use C4::Context;
use Koha::Biblios;
use Koha::Database;
use Koha::Library;
use Koha::RotatingCollections;
use Koha::Items;
use Koha::Item::Transfers;
use Koha::Libraries;

use t::lib::TestBuilder;

my $schema = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

subtest 'remove_and_add_items' => sub {
    plan tests => 8;

    $schema->storage->txn_begin;

    my $collection = Koha::RotatingCollection->new( {
        colTitle => 'Test title 1',
        colDesc  => 'Test description 1',
    } )->store;

    my $biblioitem = $builder->build( { source => 'Biblioitem' } );

    my $library = $builder->build( { source => 'Branch' } );

    my $item1 = Koha::Item->new( {
        biblionumber => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch => $library->{branchcode},
        holdingbranch => $library->{branchcode},
        barcode => 'barcode1',
    } )->store;

    my $item2 = Koha::Item->new( {
        biblionumber => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch => $library->{branchcode},
        holdingbranch => $library->{branchcode},
        barcode => 'barode2',
    } )->store;

    is( $collection->items->count, 0, 'In newly created collection there should not be any item');

    $collection->add_item( $item1 );
    $collection->add_item( $item2 );

    is( $collection->items->count, 2, 'Added two items, there should be two');

    eval { $collection->add_item };
    is( ref($@), 'Koha::Exceptions::MissingParameter', 'Missing paramater exception');

    eval { $collection->add_item( $item1 ) };
    is( ref($@), 'Koha::Exceptions::DuplicateObject', 'Duplicate Object Exception - you should not add the same item twice');

    eval { $collection->add_item('bad_itemnumber') };
    is( ref($@), 'Koha::Exceptions::ObjectNotFound', 'Object Not Found Exception - you cannot add non existent item');

    $collection->remove_item( $item1 );

    is( $collection->items->count, 1, 'We removed first item, there should be one remaining');

    eval { $collection->remove_item };
    is( ref($@), 'Koha::Exceptions::MissingParameter', 'Missing paramater exception');

    eval { $collection->remove_item( $item1 ) };
    is( ref($@), 'Koha::Exceptions::ObjectNotFound', 'Object Not Found Exception - cannot remove the same item twice');

    $schema->storage->txn_rollback;
};

subtest 'transfer' => sub {
    plan tests => 4;

    $schema->storage->txn_begin;

    my $collection = Koha::RotatingCollection->new( {
        colTitle => 'Test title 1',
        colDesc  => 'Test description 1',
    } )->store;
    my $biblioitem  = $builder->build( { source => 'Biblioitem' } );

    my $library1 = Koha::Library->new( {
        branchcode => 'CODE1',
    } )->store;

    my $library2 = Koha::Library->new( {
        branchcode => 'CODE2',
    } )->store;

    my $item = Koha::Item->new( {
        biblionumber     => $biblioitem->{biblionumber},
        biblioitemnumber => $biblioitem->{biblioitemnumber},
        homebranch       => $library1->branchcode,
        holdingbranch    => $library1->branchcode,
        itype            => 'BK',
        barcode          => 'some_barcode',
    } )->store;

    $collection->add_item( $item );

    eval { $collection->transfer };
    is( ref($@), 'Koha::Exceptions::MissingParameter', 'Missing paramater exception');

    $collection->transfer( $library2 );
    my $retrieved_item = Koha::Items->find( $item->itemnumber );

    is( $collection->colBranchcode, $library2->branchcode, 'Collection should be transferred' );
    is( $retrieved_item->holdingbranch, $library2->branchcode, 'Items in collection should be transferred too' );

    my $transfer = Koha::Item::Transfers->search( {
        itemnumber  => $item->itemnumber,
        frombranch  => $library1->branchcode,
        tobranch    => $library2->branchcode,
        datearrived => undef,
    } );
    is( $transfer->count, 1, 'There should be transfer started for item in collection');

    $schema->storage->txn_rollback;
};
