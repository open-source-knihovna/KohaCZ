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

use Test::More tests => 4;
use Test::Mojo;
use Test::Warn;

use t::lib::TestBuilder;
use t::lib::Mocks;

use C4::Auth;
use Koha::Items;
use Koha::Database;

my $schema  = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

# FIXME: sessionStorage defaults to mysql, but it seems to break transaction handling
# this affects the other REST api tests
t::lib::Mocks::mock_preference( 'SessionStorage', 'tmp' );

my $remote_address = '127.0.0.1';
my $t              = Test::Mojo->new('Koha::REST::V1');

subtest 'list() tests' => sub {
    plan tests => 2;

    # Not yet implemented
    my $tx = $t->ua->build_tx(GET => "/api/v1/items");
    $t->request_ok($tx)
      ->status_is(404);
};

subtest 'get() tests' => sub {
    plan tests => 8;

    $schema->storage->txn_begin;

    my $biblio = $builder->build({
        source => 'Biblio'
    });
    my $biblionumber = $biblio->{biblionumber};
    my $item = $builder->build({
        source => 'Item',
        value => {
            biblionumber => $biblionumber,
            withdrawn => 1, # tested with OpacHiddenItems
        }
    });
    my $itemnumber = $item->{itemnumber};

    my ($patron, $sessionid) = create_user_and_session({ authorized=>0 });
    my ($librarian, $lib_sessionid) = create_user_and_session({ authorized=>4 });

    my $nonExistentItemnumber = -14362719;
    my $tx = $t->ua->build_tx(GET => "/api/v1/items/$nonExistentItemnumber");
    $tx->req->cookies({name => 'CGISESSID', value => $sessionid});
    $t->request_ok($tx)
      ->status_is(404);

    subtest 'Confirm effectiveness of OpacHiddenItems' => sub {
        plan tests => 7;

        t::lib::Mocks::mock_preference('OpacHiddenItems', '');
        $tx = $t->ua->build_tx(GET => "/api/v1/items/$itemnumber");
        $tx->req->cookies({name => 'CGISESSID', value => $sessionid});
        $t->request_ok($tx)
          ->status_is(200)
          ->json_is('/itemnumber' => $itemnumber)
          ->json_is('/biblionumber' => $biblionumber)
          ->json_is('/itemnotes_nonpublic' => undef);

        t::lib::Mocks::mock_preference('OpacHiddenItems', 'withdrawn: [1]');
        $tx = $t->ua->build_tx(GET => "/api/v1/items/$itemnumber");
        $tx->req->cookies({name => 'CGISESSID', value => $sessionid});
        $t->request_ok($tx)
          ->status_is(404);
    };

    $tx = $t->ua->build_tx(GET => "/api/v1/items/$itemnumber");
    $tx->req->cookies({name => 'CGISESSID', value => $lib_sessionid});
    $t->request_ok($tx)
      ->status_is(200)
      ->json_is('/itemnumber' => $itemnumber)
      ->json_is('/biblionumber' => $biblionumber)
      ->json_is('/itemnotes_nonpublic' => $item->{itemnotes_nonpublic});

    $schema->storage->txn_rollback;
};

subtest 'update() tests' => sub {
    plan tests => 2;

    # Not yet implemented
    my $tx = $t->ua->build_tx(PUT => "/api/v1/items/1");
    $t->request_ok($tx)
      ->status_is(404);
};

subtest 'delete() tests' => sub {
    plan tests => 2;

    # Not yet implemented
    my $tx = $t->ua->build_tx(DELETE => "/api/v1/items/1");
    $t->request_ok($tx)
      ->status_is(404);
};

sub create_user_and_session {

    my $args  = shift;
    my $flags = ( $args->{authorized} ) ? $args->{authorized} : 0;
    my $dbh   = C4::Context->dbh;

    my $user = $builder->build(
        {
            source => 'Borrower',
            value  => {
                flags => $flags
            }
        }
    );

    # Create a session for the authorized user
    my $session = C4::Auth::get_session('');
    $session->param( 'number',   $user->{borrowernumber} );
    $session->param( 'id',       $user->{userid} );
    $session->param( 'ip',       '127.0.0.1' );
    $session->param( 'lasttime', time() );
    $session->flush;

    return ( $user->{borrowernumber}, $session->id );
}
