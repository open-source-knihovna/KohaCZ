#!/usr/bin/env perl

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

use Test::More tests => 46;
use Test::Mojo;
use t::lib::TestBuilder;

use C4::Auth;
use C4::Context;

use Koha::Database;

my $builder = t::lib::TestBuilder->new();

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
$dbh->{RaiseError} = 1;

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

my $categorycode = $builder->build({ source => 'Category' })->{ categorycode };
my $branchcode = $builder->build({ source => 'Branch' })->{ branchcode };

$t->get_ok('/api/v1/accountlines')
  ->status_is(403);

$t->put_ok("/api/v1/accountlines/11224409" => json => {'amount' => -5})
    ->status_is(403);

$t->put_ok("/api/v1/accountlines/11224408/payment")
    ->status_is(403);

$t->put_ok("/api/v1/accountlines/11224407/partialpayment" => json => {'amount' => 8})
    ->status_is(403);

my $loggedinuser = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 1024
    }
});

my $borrower = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
    }
});

my $borrower2 = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
    }
});
my $borrowernumber = $borrower->{borrowernumber};
my $borrowernumber2 = $borrower2->{borrowernumber};

$dbh->do(q| DELETE FROM accountlines |);
$dbh->do(q|
    INSERT INTO accountlines (borrowernumber, amount, accounttype, amountoutstanding)
    VALUES (?, 20, 'A', 20), (?, 40, 'F', 40), (?, 80, 'F', 80), (?, 10, 'F', 10)
    |, undef, $borrowernumber, $borrowernumber, $borrowernumber, $borrowernumber2);

my $session = C4::Auth::get_session('');
$session->param('number', $loggedinuser->{ borrowernumber });
$session->param('id', $loggedinuser->{ userid });
$session->param('ip', '127.0.0.1');
$session->param('lasttime', time());
$session->flush;

my $tx = $t->ua->build_tx(GET => "/api/v1/accountlines?borrowernumber=$borrowernumber");
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

my $json = $t->tx->res->json;
ok(ref $json eq 'ARRAY', 'response is a JSON array');
ok(scalar @$json == 3, 'response array contains 3 elements');

$tx = $t->ua->build_tx(GET => "/api/v1/accountlines");
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

$json = $t->tx->res->json;
ok(ref $json eq 'ARRAY', 'response is a JSON array');
ok(scalar @$json == 4, 'response array contains 3 elements');

# Editing accountlines tests
my $put_data = {
    'amount' => -19,
    'amountoutstanding' => -19
};


$tx = $t->ua->build_tx(
    PUT => "/api/v1/accountlines/11224409"
        => json => $put_data);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
    ->status_is(404);

my $accountline_to_edit = Koha::Accountlines->search({'borrowernumber' => $borrowernumber2})->unblessed()->[0];

$tx = $t->ua->build_tx(
    PUT => "/api/v1/accountlines/$accountline_to_edit->{accountlines_id}"
        => json => $put_data);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
    ->status_is(200);

my $accountline_edited = Koha::Accountlines->search({'borrowernumber' => $borrowernumber2})->unblessed()->[0];

is($accountline_edited->{amount}, '-19.000000');
is($accountline_edited->{amountoutstanding}, '-19.000000');


# Payment tests
$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/4562765765/payment");
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(404);

my $accountline_to_pay = Koha::Accountlines->search({'borrowernumber' => $borrowernumber, 'amount' => 20})->unblessed()->[0];
$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$accountline_to_pay->{accountlines_id}/payment");
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

my $accountline_paid = Koha::Accountlines->search({'borrowernumber' => $borrowernumber, 'amount' => -20})->unblessed()->[0];
ok($accountline_paid);

# Partial payment tests
$put_data = {
    'amount' => 17,
    'note' => 'Partial payment'
};

$tx = $t->ua->build_tx(
    PUT => "/api/v1/accountlines/11224419/partialpayment"
        => json => $put_data);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
    ->status_is(404);

my $accountline_to_partiallypay = Koha::Accountlines->search({'borrowernumber' => $borrowernumber, 'amount' => 80})->unblessed()->[0];

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$accountline_to_partiallypay->{accountlines_id}/partialpayment" => json => {amount => 'foo'});
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(400);

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$accountline_to_partiallypay->{accountlines_id}/partialpayment" => json => $put_data);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

$accountline_to_partiallypay = Koha::Accountlines->search({'borrowernumber' => $borrowernumber, 'amount' => 80})->unblessed()->[0];
is($accountline_to_partiallypay->{amountoutstanding}, '63.000000');

my $accountline_partiallypaid = Koha::Accountlines->search({'borrowernumber' => $borrowernumber, 'amount' => 17})->unblessed()->[0];
ok($accountline_partiallypaid);

# Pay amount tests
my $borrower3 = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
    }
});
my $borrowernumber3 = $borrower3->{borrowernumber};

$dbh->do(q|
    INSERT INTO accountlines (borrowernumber, amount, accounttype, amountoutstanding)
    VALUES (?, 26, 'A', 26)
    |, undef, $borrowernumber3);

$t->put_ok("/api/v1/accountlines/$borrowernumber3/amountpayment" => json => {'amount' => 8})
    ->status_is(403);

my $put_data2 = {
    'amount' => 24,
    'note' => 'Partial payment'
};

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/8789798797/amountpayment" => json => $put_data2);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(404);

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$borrowernumber3/amountpayment" => json => {amount => 0});
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(400);

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$borrowernumber3/amountpayment" => json => {amount => 'foo'});
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(400);

$tx = $t->ua->build_tx(PUT => "/api/v1/accountlines/$borrowernumber3/amountpayment" => json => $put_data2);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

$accountline_partiallypaid = Koha::Accountlines->search({'borrowernumber' => $borrowernumber3, 'amount' => 26})->unblessed()->[0];

is($accountline_partiallypaid->{amountoutstanding}, '2.000000');

$dbh->rollback;
