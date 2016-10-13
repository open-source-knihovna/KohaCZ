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
use t::lib::Mocks;

use C4::Auth;
use C4::Context;

use Koha::AuthUtils;
use Koha::Database;
use Koha::Patron;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new();

$schema->storage->txn_begin;

# FIXME: sessionStorage defaults to mysql, but it seems to break transaction handling
# this affects the other REST api tests
t::lib::Mocks::mock_preference( 'SessionStorage', 'tmp' );

$ENV{REMOTE_ADDR} = '127.0.0.1';
my $t = Test::Mojo->new('Koha::REST::V1');

my $categorycode = $builder->build({ source => 'Category' })->{ categorycode };
my $branchcode = $builder->build({ source => 'Branch' })->{ branchcode };

my $guarantor = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 0,
    }
});

my $password = "secret";
my $borrower = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 0,
        lost         => 1,
        guarantorid  => $guarantor->{borrowernumber},
        password     => Koha::AuthUtils::hash_password($password),
    }
});

my $librarian = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 16,
        password     => Koha::AuthUtils::hash_password("test"),
    }
});

$t->get_ok('/api/v1/patrons')
  ->status_is(401);

$t->get_ok("/api/v1/patrons/" . $borrower->{ borrowernumber })
  ->status_is(401);

my $session = C4::Auth::get_session('');
$session->param('number', $borrower->{ borrowernumber });
$session->param('id', $borrower->{ userid });
$session->param('ip', '127.0.0.1');
$session->param('lasttime', time());
$session->flush;

my $session2 = C4::Auth::get_session('');
$session2->param('number', $guarantor->{ borrowernumber });
$session2->param('id', $guarantor->{ userid });
$session2->param('ip', '127.0.0.1');
$session2->param('lasttime', time());
$session2->flush;

my $session3 = C4::Auth::get_session('');
$session3->param('number', $librarian->{ borrowernumber });
$session3->param('id', $librarian->{ userid });
$session3->param('ip', '127.0.0.1');
$session3->param('lasttime', time());
$session3->flush;

my $tx = $t->ua->build_tx(GET => '/api/v1/patrons');
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(403);


$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . ($borrower->{ borrowernumber }-1));
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(403)
  ->json_is('/required_permissions', {"borrowers" => "1"});

# User without permissions, but is the owner of the object
$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $borrower->{borrowernumber});
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(200);

# User without permissions, but is the guarantor of the owner of the object
$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $borrower->{borrowernumber});
$tx->req->cookies({name => 'CGISESSID', value => $session2->id});
$t->request_ok($tx)
  ->status_is(200)
  ->json_is('/guarantorid', $guarantor->{borrowernumber});

my $password_obj = {
    current_password    => $password,
    new_password        => "new password",
};

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/-100/password' => json => $password_obj);
$t->request_ok($tx)
  ->status_is(401);

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$borrower->{borrowernumber}.'/password');
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(400);

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$guarantor->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(403);

my $loggedinuser = $builder->build({
    source => 'Borrower',
    value => {
        branchcode   => $branchcode,
        categorycode => $categorycode,
        flags        => 16, # borrowers flag
        password     => Koha::AuthUtils::hash_password($password),
    }
});

$session = C4::Auth::get_session('');
$session->param('number', $loggedinuser->{ borrowernumber });
$session->param('id', $loggedinuser->{ userid });
$session->param('ip', '127.0.0.1');
$session->param('lasttime', time());
$session->flush;

my $session_nopermission = C4::Auth::get_session('');
$session_nopermission->param('number', $borrower->{ borrowernumber });
$session_nopermission->param('id', $borrower->{ userid });
$session_nopermission->param('ip', '127.0.0.1');
$session_nopermission->param('lasttime', time());
$session_nopermission->flush;

$tx = $t->ua->build_tx(GET => '/api/v1/patrons');
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$tx->req->env({REMOTE_ADDR => '127.0.0.1'});
$t->request_ok($tx)
  ->status_is(200);

$tx = $t->ua->build_tx(GET => "/api/v1/patrons/" . $borrower->{ borrowernumber });
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(200)
  ->json_is('/borrowernumber' => $borrower->{ borrowernumber })
  ->json_is('/surname' => $borrower->{ surname })
  ->json_is('/lost' => Mojo::JSON->true );

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/-100/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(404);

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$loggedinuser->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(200);

ok(C4::Auth::checkpw_hash($password_obj->{'new_password'}, Koha::Patrons->find($loggedinuser->{borrowernumber})->password), "New password in database.");
is(C4::Auth::checkpw_hash($password_obj->{'current_password'}, Koha::Patrons->find($loggedinuser->{borrowernumber})->password), "", "Old password is gone.");

$password_obj->{'current_password'} = $password_obj->{'new_password'};
$password_obj->{'new_password'} = "a";
t::lib::Mocks::mock_preference("minPasswordLength", 5);
$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$loggedinuser->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(400)
  ->json_like('/error', qr/Password is too short/, "Password too short");

$password_obj->{'new_password'} = " abcdef ";
$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$loggedinuser->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session->id});
$t->request_ok($tx)
  ->status_is(400)
  ->json_is('/error', "Password cannot contain trailing whitespaces.");

$password_obj = {
    current_password    => $password,
    new_password        => "new password",
};
t::lib::Mocks::mock_preference("OpacPasswordChange", 0);
$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$borrower->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session_nopermission->id});
$t->request_ok($tx)
  ->status_is(403)
  ->json_is('/error', "OPAC password change is disabled");

t::lib::Mocks::mock_preference("OpacPasswordChange", 1);
$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$borrower->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session_nopermission->id});
$t->request_ok($tx)
  ->status_is(200);

$tx = $t->ua->build_tx(PATCH => '/api/v1/patrons/'.$borrower->{borrowernumber}.'/password' => json => $password_obj);
$tx->req->cookies({name => 'CGISESSID', value => $session3->id});
$t->request_ok($tx)
  ->status_is(200);

$schema->storage->txn_rollback;
