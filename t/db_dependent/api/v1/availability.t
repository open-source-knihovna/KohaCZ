#!/usr/bin/env perl

# Copyright Koha-Suomi Oy 2016
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

use Test::More tests => 165;
use Test::Mojo;
use t::lib::Mocks;
use t::lib::TestBuilder;

use Mojo::JSON;

use C4::Auth;
use C4::Circulation;
use C4::Context;

use Koha::Database;
use Koha::Items;
use Koha::Patron;

my $builder = t::lib::TestBuilder->new();

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

my $categorycode = $builder->build({ source => 'Category' })->{ categorycode };
my $branchcode = $builder->build({ source => 'Branch' })->{ branchcode };

my $borrower = $builder->build({ source => 'Borrower' });
my $biblio = $builder->build({ source => 'Biblio' });
my $biblio2 = $builder->build({ source => 'Biblio' });
my $biblionumber = $biblio->{biblionumber};
my $biblionumber2 = $biblio2->{biblionumber};

my $module = new Test::MockModule('C4::Context');
$module->mock( 'userenv', sub { { branch => $borrower->{branchcode} } } );

# $item = available, $item2 = unavailable
my $items;
$items->{available} = build_item($biblionumber);
$items->{notforloan} = build_item($biblionumber2, { notforloan => 1 });
$items->{damaged} = build_item($biblionumber2, { damaged => 1 });
$items->{withdrawn} = build_item($biblionumber2, { withdrawn => 1 });
$items->{onloan}  = build_item($biblionumber2, { onloan => undef });
$items->{itemlost} = build_item($biblionumber2, { itemlost => 1 });
$items->{reserved} = build_item($biblionumber2);
my $priority= C4::Reserves::CalculatePriority($items->{reserved}->{biblionumber});
my $reserve_id = C4::Reserves::AddReserve(
    $items->{reserved}->{homebranch},
    $borrower->{borrowernumber},
    $items->{reserved}->{biblionumber},
    undef,
    $priority,
    undef, undef, undef,
    $$biblio{title},
    $items->{reserved}->{itemnumber},
    undef
);
my $reserve = Koha::Holds->find($reserve_id);

my $itemnumber = $items->{available}->{itemnumber};

$t->get_ok("/api/v1/availability/items?itemnumber=-500382")
  ->status_is(404);

$t->get_ok("/api/v1/availability/items?itemnumber=-500382+-500383")
  ->status_is(404);

$t->get_ok("/api/v1/availability/items?biblionumber=-500382")
  ->status_is(404);

$t->get_ok("/api/v1/availability/items?biblionumber=-500382+-500383")
  ->status_is(404);

t::lib::Mocks::mock_preference('OnSiteCheckouts', 0);
t::lib::Mocks::mock_preference('AllowHoldsOnDamagedItems', 0);
# available item
$t->get_ok("/api/v1/availability/items?itemnumber=$itemnumber")
  ->status_is(200)
  ->json_is('/0/itemnumber', $itemnumber)
  ->json_is('/0/biblionumber', $biblionumber)
  ->json_is('/0/checkout/available', Mojo::JSON->true)
  ->json_is('/0/checkout/description', [])
  ->json_is('/0/hold/available', Mojo::JSON->true)
  ->json_is('/0/hold/description', [])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', [])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["onsite_checkouts_disabled"])
  ->json_is('/0/hold_queue_length', 0);
t::lib::Mocks::mock_preference('OnSiteCheckouts', 1);
$t->get_ok("/api/v1/availability/items?biblionumber=$biblionumber")
  ->status_is(200)
  ->json_is('/0/itemnumber', $itemnumber)
  ->json_is('/0/biblionumber', $biblionumber)
  ->json_is('/0/checkout/available', Mojo::JSON->true)
  ->json_is('/0/checkout/description', [])
  ->json_is('/0/hold/available', Mojo::JSON->true)
  ->json_is('/0/hold/description', [])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', [])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->true)
  ->json_is('/0/onsite_checkout/description', [])
  ->json_is('/0/hold_queue_length', 0);

# notforloan item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{notforloan}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{notforloan}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description/0', "notforloan")
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["notforloan"])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', [])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->true)
  ->json_is('/0/onsite_checkout/description', [])
  ->json_is('/0/hold_queue_length', 0);
t::lib::Mocks::mock_preference('OnSiteCheckouts', 0);
$t->get_ok("/api/v1/availability/items?itemnumber=$items->{notforloan}->{itemnumber}")
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{notforloan}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["notforloan"])
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["notforloan"])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', [])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["onsite_checkouts_disabled"])
  ->json_is('/0/hold_queue_length', 0);
t::lib::Mocks::mock_preference('OnSiteCheckouts', 1);

# damaged item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{damaged}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{damaged}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["damaged"])
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["damaged"])
  ->json_is('/0/local_use/available', Mojo::JSON->false)
  ->json_is('/0/local_use/description', ["damaged"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["damaged"])
  ->json_is('/0/hold_queue_length', 0);
t::lib::Mocks::mock_preference('AllowHoldsOnDamagedItems', 1);
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{damaged}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{damaged}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->true)
  ->json_is('/0/checkout/description', ["damaged"])
  ->json_is('/0/hold/available', Mojo::JSON->true)
  ->json_is('/0/hold/description', ["damaged"])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', ["damaged"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->true)
  ->json_is('/0/onsite_checkout/description', ["damaged"])
  ->json_is('/0/hold_queue_length', 0);

# withdrawn item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{withdrawn}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{withdrawn}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["withdrawn"])
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["withdrawn"])
  ->json_is('/0/local_use/available', Mojo::JSON->false)
  ->json_is('/0/local_use/description', ["withdrawn"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["withdrawn"])
  ->json_is('/0/hold_queue_length', 0);

# lost item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{itemlost}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{itemlost}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["itemlost"])
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["itemlost"])
  ->json_is('/0/local_use/available', Mojo::JSON->false)
  ->json_is('/0/local_use/description', ["itemlost"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["itemlost"])
  ->json_is('/0/hold_queue_length', 0);

my $issue = AddIssue($borrower, $items->{onloan}->{barcode}, undef, 1);

# issued item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{onloan}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{onloan}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["onloan"])
  ->json_is('/0/hold/available', Mojo::JSON->true)
  ->json_is('/0/hold/description', [])
  ->json_is('/0/local_use/available', Mojo::JSON->false)
  ->json_is('/0/local_use/description', ["onloan"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["onloan"])
  ->json_is('/0/checkout/expected_available', $issue->date_due)
  ->json_is('/0/local_use/expected_available', $issue->date_due)
  ->json_is('/0/onsite_checkout/expected_available', $issue->date_due)
  ->json_is('/0/hold_queue_length', 0);

# reserved item
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{reserved}->{itemnumber})
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{reserved}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description', ["reserved"])
  ->json_is('/0/hold/available', Mojo::JSON->true)
  ->json_is('/0/hold/description', [])
  ->json_is('/0/local_use/available', Mojo::JSON->false)
  ->json_is('/0/local_use/description', ["reserved"])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->false)
  ->json_is('/0/onsite_checkout/description', ["reserved"])
  ->json_is('/0/hold_queue_length', 1);

# multiple in one request
$t->get_ok("/api/v1/availability/items?itemnumber=".$items->{notforloan}->{itemnumber}."+$itemnumber+-500382")
  ->status_is(200)
  ->json_is('/0/itemnumber', $items->{notforloan}->{itemnumber})
  ->json_is('/0/biblionumber', $biblionumber2)
  ->json_is('/0/checkout/available', Mojo::JSON->false)
  ->json_is('/0/checkout/description/0', "notforloan")
  ->json_is('/0/hold/available', Mojo::JSON->false)
  ->json_is('/0/hold/description', ["notforloan"])
  ->json_is('/0/local_use/available', Mojo::JSON->true)
  ->json_is('/0/local_use/description', [])
  ->json_is('/0/onsite_checkout/available', Mojo::JSON->true)
  ->json_is('/0/onsite_checkout/description', [])
  ->json_is('/0/hold_queue_length', 0)
  ->json_is('/1/itemnumber', $itemnumber)
  ->json_is('/1/biblionumber', $biblionumber)
  ->json_is('/1/checkout/available', Mojo::JSON->true)
  ->json_is('/1/checkout/description', [])
  ->json_is('/1/hold/available', Mojo::JSON->true)
  ->json_is('/1/hold/description', [])
  ->json_is('/1/local_use/available', Mojo::JSON->true)
  ->json_is('/1/local_use/description', [])
  ->json_is('/1/onsite_checkout/available', Mojo::JSON->true)
  ->json_is('/1/onsite_checkout/description', [])
  ->json_is('/1/hold_queue_length', 0);

sub build_item {
    my ($biblionumber, $field) = @_;

    return $builder->build({
        source => 'Item',
        value => {
            biblionumber => $biblionumber,
            notforloan => $field->{notforloan} || 0,
            damaged => $field->{damaged} || 0,
            withdrawn => $field->{withdrawn} || 0,
            itemlost => $field->{itemlost} || 0,
            restricted => $field->{restricted} || undef,
            onloan => $field->{onloan} || undef,
            itype => $field->{itype} || undef,
        }
    });
}
