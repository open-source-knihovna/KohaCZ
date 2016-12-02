#!/usr/bin/perl

# Copyright 2016 Koha Development team
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

use Test::More tests => 8;

#use Koha::Account::CreditType;
use Koha::Account::CreditTypes;
#use Koha::Account::DebitType;
use Koha::Account::DebitTypes;
use Koha::Database;

use t::lib::TestBuilder;

use Try::Tiny;

my $schema = Koha::Database->new->schema;
$schema->storage->txn_begin;

my $builder = t::lib::TestBuilder->new;
my $number_of_credit_types = Koha::Account::CreditTypes->search->count;
my $number_of_debit_types = Koha::Account::DebitTypes->search->count;
my $new_credit_type_1 = Koha::Account::CreditType->new({
    type_code => '1CODE',
    description => 'my description 1',
    can_be_deleted => 0,
    can_be_added_manually => 1,
})->store;

my $new_credit_type_2 = Koha::Account::CreditType->new({
    type_code => '2CODE',
    description => 'my description 2',
    can_be_deleted => 1,
    can_be_added_manually => 1,
})->store;

my $new_debit_type_1 = Koha::Account::DebitType->new({
    type_code => '3CODE',
    description => 'my description 3',
    can_be_deleted => 0,
    can_be_added_manually => 1,
    default_amount => 0.45,
})->store;

my $new_debit_type_2 = Koha::Account::DebitType->new({
    type_code => '4CODE',
    description => 'my description 4',
    can_be_deleted => 1,
    can_be_added_manually => 1,
})->store;

is( Koha::Account::CreditTypes->search->count, $number_of_credit_types + 2, 'The 2 credit types should have been added' );
is( Koha::Account::DebitTypes->search->count, $number_of_debit_types + 2, 'The 2 debit types should have been added' );

my $retrieved_credit_type_1 = Koha::Account::CreditTypes->find( $new_credit_type_1->type_code );
is( $retrieved_credit_type_1->description, $new_credit_type_1->description, 'Find a credit type by type_code should return the correct one' );

my $retrieved_debit_type_1 = Koha::Account::DebitTypes->find( $new_debit_type_1->type_code );
is( $retrieved_debit_type_1->description, $new_debit_type_1->description, 'Find a debit type by type_code should return the correct one' );

my $retrieved_credit_type_2 = Koha::Account::CreditTypes->find( $new_credit_type_2->type_code );
my $retrieved_debit_type_2 = Koha::Account::DebitTypes->find( $new_debit_type_2->type_code );

try {
    $retrieved_credit_type_1->delete;
} catch {
    ok( $_->isa('Koha::Exceptions::CannotDeleteDefault'), 'The first credit type should not be deleted' );
};
$retrieved_credit_type_2->delete;
is( Koha::Account::CreditTypes->search->count, $number_of_credit_types + 1, 'The second credit type should be deleted' );

try {
    $retrieved_debit_type_1->delete;
} catch {
    ok( $_->isa('Koha::Exceptions::CannotDeleteDefault'), 'The first debit type should not be deleted' );
};
$retrieved_debit_type_2->delete;
is( Koha::Account::DebitTypes->search->count, $number_of_debit_types + 1, 'The second debit type should be deleted' );

$schema->storage->txn_rollback;

1;
