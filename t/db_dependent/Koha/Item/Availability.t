#!/usr/bin/perl

# Copyright Koha-Suomi Oy 2016
#
# This file is part of Koha
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
use Test::More tests => 4;
use t::lib::Mocks;
use t::lib::TestBuilder;

use C4::Biblio;
use C4::Circulation;
use C4::Reserves;

use Koha::Database;
use Koha::Items;
use Koha::ItemTypes;

use_ok('Koha::Item::Availabilities');
use_ok('Koha::Item::Availability');

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

subtest 'Koha::Item::Availability tests' => sub {
    plan tests => 14;

    my $availability = Koha::Item::Availability->new->set_available;

    is($availability->available, 1, "Available");
    $availability->set_needs_confirmation;
    is($availability->availability_needs_confirmation, 1, "Needs confirmation");
    $availability->set_unavailable;
    is($availability->available, 0, "Not available");

    $availability->add_description("such available");
    $availability->add_description("wow");
    $availability->add_description("wow");

    ok($availability->has_description("wow"), "Found description 'wow'");
    ok($availability->has_description(["wow", "such available"]),
       "Found description 'wow' and 'such available'");
    is($availability->has_description(["wow", "much not found"]), 0,
       "Didn't find 'wow' and 'much not found'");
    is($availability->description->[0], "such available",
       "Found correct description in correct index 1/4");
    is($availability->description->[1], "wow",
       "Found correct description in correct index 2/2");

    $availability->add_description(["much description", "very doge"]);
    is($availability->description->[2], "much description",
       "Found correct description in correct index 3/4");
    is($availability->description->[3], "very doge",
       "Found correct description in correct index 4/4");

    $availability->del_description("wow");
    is($availability->description->[1], "much description",
       "Found description from correct index after del");
    $availability->del_description(["very doge", "such available"]);
    is($availability->description->[0], "much description",
       "Found description from correct index after del");

    my $availability_clone = $availability;
    $availability->set_unavailable;
    is($availability_clone->available, $availability->{available},
       "Availability_clone points to availability");
    $availability_clone = $availability->clone;
    $availability->set_available;
    isnt($availability_clone->available, $availability->{available},
         "Availability_clone was cloned and no longer has same availability status");
};

subtest 'Item availability tests' => sub {
    plan tests => 14;

    my $builder = t::lib::TestBuilder->new;
    my $library = $builder->build({ source => 'Branch' });
    my $itemtype_built = $builder->build({
        source => 'Itemtype',
        value => {
            notforloan => 0,
        }
    });
    my $biblioitem_built = $builder->build({
        source => 'Biblioitem',
        value => {
            itemtype => $itemtype_built->{'itemtype'},
        }
    });
    my $item_built    = $builder->build({
        source => 'Item',
        value => {
            holding_branch => $library->{branchcode},
            homebranch => $library->{branchcode},
            biblioitemnumber => $biblioitem_built->{biblioitemnumber},
            itype => $itemtype_built->{itemtype},
        }
    });

    t::lib::Mocks::mock_preference('item-level_itypes', 0);
    t::lib::Mocks::mock_preference('OnSiteCheckouts', 1);
    t::lib::Mocks::mock_preference('AllowHoldsOnDamagedItems', 0);

    my $itemtype = Koha::ItemTypes->find($itemtype_built->{itemtype});
    my $item = Koha::Items->find($item_built->{itemnumber});
    $item->set({
        notforloan => 0,
        damaged => 0,
        itemlost => 0,
        withdrawn => 0,
        onloan => undef,
        restricted => 0,
    })->store; # set available

    ok($item->can('availabilities'), "Koha::Item->availabilities exists.");
    my $availabilities = $item->availabilities;
    is(ref($availabilities), 'Koha::Item::Availabilities', '$availabilities is blessed as Koha::Item::Availabilities');

    my $holdability = $availabilities->hold;
    my $issuability = $availabilities->issue;
    my $for_local_use = $availabilities->local_use;
    my $onsite_issuability = $availabilities->onsite_checkout;
    is(ref($holdability), 'Koha::Item::Availability', '1/4 Correct class');
    is(ref($issuability), 'Koha::Item::Availability', '2/4 Correct class');
    is(ref($for_local_use), 'Koha::Item::Availability', '3/4 Correct class');
    is(ref($onsite_issuability), 'Koha::Item::Availability', '4/4 Correct class');

    ok($holdability->available, 'Available for holds');
    ok($issuability->available, 'Available for checkouts');
    ok($for_local_use->available, 'Available for local use');
    ok($onsite_issuability->available, 'Available for onsite checkout');

    # Test plan:
    # Subtest for each availability type in predefined order;
    # hold -> checkout -> local_use -> onsite_checkout
    # Each is dependant on the previous one, no need to run same tests as moving
    # from left to right.
    subtest 'Availability: hold' => sub {
        plan tests => 14;

        $item->withdrawn(1)->store;
        ok(!$availabilities->hold->available, "Item withdrawn => not available");
        is($availabilities->hold->description->[0], 'withdrawn', 'Description: withdrawn');
        $item->withdrawn(0)->itemlost(1)->store;
        ok(!$availabilities->hold->available, "Item lost => not available");
        is($availabilities->hold->description->[0], 'itemlost', 'Description: itemlost');
        $item->itemlost(0)->restricted(1)->store;
        ok(!$availabilities->hold->available, "Item restricted => not available");
        is($availabilities->hold->description->[0], 'restricted', 'Description: restricted');
        $item->restricted(0)->store;

        subtest 'Hold on damaged item' => sub {
            plan tests => 3;

            t::lib::Mocks::mock_preference('AllowHoldsOnDamagedItems', 0);
            $item->damaged(1)->store;
            ok($item->damaged, "Item is damaged");
            ok(!$availabilities->hold->available, 'Not available for holds (AllowHoldsOnDamagedItems => 0)');
            t::lib::Mocks::mock_preference('AllowHoldsOnDamagedItems', 1);
            ok($availabilities->hold->available, 'Available for holds (AllowHoldsOnDamagedItems => 1)');
            $item->damaged(0)->store;
        };

        t::lib::Mocks::mock_preference('item-level_itypes', 1);
        $item->notforloan(1)->store;
        ok(!$availabilities->hold->available, "Item notforloan => not available");
        is($availabilities->hold->description->[0], 'notforloan', 'Description: notforloan');
        t::lib::Mocks::mock_preference('item-level_itypes', 0);
        $item->notforloan(0)->store;
        $itemtype->notforloan(1)->store;
        ok(!$availabilities->hold->available, "Itemtype notforloan => not available");
        is($availabilities->hold->description->[0], 'notforloan', 'Description: notforloan');
        $itemtype->notforloan(0)->store;
        ok($availabilities->hold->available, "Available");
        $item->notforloan(-1)->store;
        ok(!$availabilities->hold->available, "Itemtype notforloan -1 => not available");
        is($availabilities->hold->description->[0], 'ordered', 'Description: ordered');
        $item->notforloan(0)->store;
    };

    subtest 'Availability: Checkout' => sub {
        plan tests => 7;

        my $patron = $builder->build({ source => 'Borrower' });
        my $biblio = C4::Biblio::GetBiblio($item->biblionumber);
        my $priority= C4::Reserves::CalculatePriority( $item->biblionumber );
        my $reserve_id = C4::Reserves::AddReserve(
            $item->holdingbranch,
            $patron->{borrowernumber},
            $item->biblionumber,
            undef,
            $priority,
            undef, undef, undef,
            $$biblio{title},
            $item->itemnumber,
            undef
        );

        ok(!$availabilities->issue->available, "Item reserved => not available");
        is($availabilities->issue->description->[0], 'reserved', 'Description: reserved');
        C4::Reserves::CancelReserve({ reserve_id => $reserve_id });
        ok($availabilities->issue->available, "Reserve cancelled => available");

        my $module = new Test::MockModule('C4::Context');
        $module->mock( 'userenv', sub { { branch => $patron->{branchcode} } } );
        my $issue = C4::Circulation::AddIssue($patron, $item->barcode, undef, 1);
        ok(!$availabilities->issue->available, "Item issued => not available");
        is($availabilities->issue->description->[0], 'onloan', 'Description: onloan');
        is($availabilities->issue->expected_available,
           $issue->date_due, "Expected to be available '".$issue->date_due."'");
        C4::Circulation::AddReturn($item->barcode, $item->homebranch);
        ok($availabilities->issue->available, "Checkin => available");
    };

    subtest 'Availability: Local use' => sub {
        plan tests => 1;

        $item->notforloan(1)->store;
        ok($availabilities->local_use->available, "Item notforloan => available");
    };

    subtest 'Availability: On-site checkout' => sub {
        plan tests => 2;

        t::lib::Mocks::mock_preference('OnSiteCheckouts', 0);
        ok(!$availabilities->onsite_checkout->available, 'Not available for onsite checkout '
           .'(OnSiteCheckouts => 0)');
        t::lib::Mocks::mock_preference('OnSiteCheckouts', 1);
        ok($availabilities->onsite_checkout->available, 'Available for onsite checkout '
           .'(OnSiteCheckouts => 1)');
    };
};

$schema->storage->txn_rollback;

1;
