#!/usr/bin/env perl

# Copyright 2016 Koha-Suomi
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

use Test::More tests => 20;
use Test::Mojo;

use t::lib::TestBuilder;

use C4::Context;
use Koha::AuthUtils;

my $builder = t::lib::TestBuilder->new();

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

my $categorycode = $builder->build({ source => 'Category' })->{ categorycode };
my $branchcode = $builder->build({ source => 'Branch' })->{ branchcode };
my $password = "2anxious? if someone finds out";

my $borrower = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        password => Koha::AuthUtils::hash_password($password),
    }
});

my $auth_by_userid = {
    userid => $borrower->{userid},
    password => $password,
};
my $auth_by_cardnumber = {
    cardnumber => $borrower->{cardnumber},
    password => $password,
};
my $invalid_login = {
    userid => $borrower->{userid},
    password => "please let me in",
};
my $invalid_login2 = {
    cardnumber => $borrower->{cardnumber},
    password => "my password is password, don't tell anyone",
};

my $tx = $t->ua->build_tx(POST => '/api/v1/auth/session' => form => $auth_by_userid);
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(201)
  ->json_is('/firstname', $borrower->{firstname})
  ->json_is('/surname', $borrower->{surname})
  ->json_is('/borrowernumber', $borrower->{borrowernumber})
  ->json_is('/email', $borrower->{email})
  ->json_has('/sessionid');

$tx = $t->ua->build_tx(POST => '/api/v1/auth/session' => form => $auth_by_cardnumber);
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(201)
  ->json_is('/firstname', $borrower->{firstname})
  ->json_is('/surname', $borrower->{surname})
  ->json_is('/borrowernumber', $borrower->{borrowernumber})
  ->json_is('/email', $borrower->{email})
  ->json_has('/sessionid');

$tx = $t->ua->build_tx(POST => '/api/v1/auth/session' => form => $invalid_login);
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(401)
  ->json_is('/error', "Login failed.");

$tx = $t->ua->build_tx(POST => '/api/v1/auth/session' => form => $invalid_login2);
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(401)
  ->json_is('/error', "Login failed.");

$dbh->rollback;
