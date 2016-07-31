package Koha::REST::V1::Auth;

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

use Mojo::Base 'Mojolicious::Controller';

use Koha::Patrons;
use C4::Auth;

use CGI;

sub login {
    my ($c, $args, $cb) = @_;

    my $userid = $args->{userid} || $args->{cardnumber};
    my $password = $args->{password};
    my $patron;

    return $c->$cb({ error => "Either userid or cardnumber is required "
                             ."- neither given." }, 403) unless ($userid);

    my $cgi = CGI->new;
    $cgi->param(userid => $userid);
    $cgi->param(password => $password);
    my ($status, $cookie, $sessionid) = C4::Auth::check_api_auth($cgi);

    return $c->$cb({ error => "Login failed." }, 401) if $status eq "failed";
    return $c->$cb({ error => "Session expired." }, 401) if $status eq "expired";
    return $c->$cb({ error => "Database is under maintenance." }, 401) if $status eq "maintenance";
    return $c->$cb({ error => "Login failed." }, 401) unless $status eq "ok";

    $patron = Koha::Patrons->find({ userid => $userid }) unless $patron;
    $patron = Koha::Patrons->find({ cardnumber => $userid }) unless $patron;

    my $session = _swaggerize_session($sessionid, $patron);

    $c->cookie(CGISESSID => $sessionid, { path => "/" });

    return $c->$cb($session, 201);
}

sub _swaggerize_session {
    my ($sessionid, $patron) = @_;

    return unless ref($patron) eq 'Koha::Patron';

    return {
        borrowernumber => $patron->borrowernumber,
        firstname => $patron->firstname,
        surname  => $patron->surname,
        email     => $patron->email,
        sessionid => $sessionid,
    };
}

1;
