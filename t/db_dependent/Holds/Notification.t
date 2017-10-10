#!/usr/bin/perl

# Copyright 2017 R-Bit Technology, s.r.o.
#
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

use Test::More tests => 5;
use t::lib::TestBuilder;
use t::lib::Mocks;

use Koha::Database;
use Koha::Holds;

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new();
my $libraryA = $builder->build(
    {
        source => 'Branch',
    }
);

my $libraryB = $builder->build(
    {
        source => 'Branch',
    }
);

my $holdRequestorInA = $builder->build(
    {
        source => 'Borrower',
        value  => {
            branchcode   => $libraryA->{branchcode},
            cardnumber   => '001',
        },
    }
);

my $patronInA = $builder->build(
    {
        source => 'Borrower',
        value  => {
            branchcode   => $libraryA->{branchcode},
            cardnumber   => '002',
        },
    }
);

my $patronInB = $builder->build(
    {
        source => 'Borrower',
        value  => {
            branchcode   => $libraryB->{branchcode},
            cardnumber   => '003',
        },
    }
);

my $biblio = $builder->build(
    {
        source => 'Biblio',
        value  => {
            title => 'Title 1',
        },
    }
);
my $itemType = $builder->build(
    {
        source => 'Itemtype',
    }
);
my $itemInA = $builder->build(
    {
        source => 'Item',
        value  => {
            biblionumber  => $biblio->{biblionumber},
            homebranch    => $libraryA->{branchcode},
            holdingbranch => $libraryA->{branchcode},
            itype         => $itemType->{itemtype},
        },
    }
);
my $itemInB = $builder->build(
    {
        source => 'Item',
        value  => {
            biblionumber  => $biblio->{biblionumber},
            homebranch    => $libraryB->{branchcode},
            holdingbranch => $libraryB->{branchcode},
            itype         => $itemType->{itemtype},
        },
    }
);

my $issueOfItemInA = $builder->build(
    {
        source => 'Issue',
        value  => {
            borrowernumber  => $patronInB->{borrowernumber},
            itemnumber      => $itemInA->{itemnumber},
        },
    }
);
my $issueOfItemInB = $builder->build(
    {
        source => 'Issue',
        value  => {
            borrowernumber  => $patronInA->{borrowernumber},
            itemnumber      => $itemInB->{itemnumber},
        },
    }
);

t::lib::Mocks::mock_preference('NotifyToReturnItemWhenHoldIsPlaced', 1); # Assuming the notification is allowed

my $hold = Koha::Hold->new(
    {
        borrowernumber => $holdRequestorInA->{borrowernumber},
        biblionumber   => $biblio->{biblionumber},
        reservedate    => '2017-01-01',
        branchcode     => $holdRequestorInA->{branchcode},
        priority       => 1,
        reservenotes   => 'dummy text',
        #itemnumber     => $itemInA->{itemnumber},
        waitingdate    => '2099-01-01',
        expirationdate => '2099-01-01',
        itemtype       => $itemInA->{itype},
    }
)->store();

my @borrowers;

t::lib::Mocks::mock_preference('NotifyToReturnItemFromLibrary', 'AnyLibrary'); # Assuming items from any library
@borrowers = $hold->borrowers_to_satisfy();
is(scalar(grep {defined $_} @borrowers), 2, "2 borrowers with requested item found in any library");

t::lib::Mocks::mock_preference('NotifyToReturnItemFromLibrary', 'RequestorLibrary'); # Assuming items from requestor library
@borrowers = $hold->borrowers_to_satisfy();
is(scalar(grep {defined $_} @borrowers), 1, "1 item found in requestor library");
is($borrowers[0]->cardnumber, "002", "   ...and it is in 002's hands");

t::lib::Mocks::mock_preference('NotifyToReturnItemFromLibrary', 'ItemHomeLibrary'); # Assuming items from the same library as requested item
@borrowers = $hold->borrowers_to_satisfy();
is(scalar(grep {defined $_} @borrowers), 1, "1 item found in the same library as the requested item");
is($borrowers[0]->cardnumber, "003", "   ...and it is in 003's hands");

$schema->storage->txn_rollback;

1;
