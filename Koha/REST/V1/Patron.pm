package Koha::REST::V1::Patron;

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

use C4::Auth qw( haspermission checkpw_internal );
use C4::Context;
use Koha::Exceptions;
use Koha::Exceptions::Password;
use Koha::Patrons;

use Scalar::Util qw(blessed);
use Try::Tiny;

sub list {
    my $c = shift->openapi->valid_input or return;

    my $patrons = Koha::Patrons->search;

    return $c->render(status => 200, openapi => $patrons);
}

sub get {
    my $c = shift->openapi->valid_input or return;

    my $borrowernumber = $c->validation->param('borrowernumber');
    my $patron = Koha::Patrons->find($borrowernumber);
    unless ($patron) {
        return $c->render(status => 404, openapi => { error => "Patron not found." });
    }

    return $c->render(status => 200, openapi => $patron);
}

sub changepassword {
    my ($c, $args, $cb) = @_;

    my $patron;
    my $user;
    try {

        $patron = Koha::Patrons->find($args->{borrowernumber});
        $user = $c->stash('koha.user');

        my $OpacPasswordChange = C4::Context->preference("OpacPasswordChange");
        my $haspermission = haspermission($user->userid, {borrowers => 1});
        unless ($OpacPasswordChange && $user->borrowernumber == $args->{borrowernumber}) {
            Koha::Exceptions::BadSystemPreference->throw(
                preference => 'OpacPasswordChange'
            ) unless $haspermission;
        }

        my $pw = $args->{'body'};
        my $dbh = C4::Context->dbh;
        unless ($haspermission || checkpw_internal($dbh, $patron->userid, $pw->{'current_password'})) {
            Koha::Exceptions::Password::Invalid->throw;
        }
        $patron->change_password_to($pw->{'new_password'});
        return $c->$cb({}, 200);
    }
    catch {
        if (not defined $patron) {
            return $c->$cb({ error => "Patron not found." }, 404);
        }
        elsif (not defined $user) {
            return $c->$cb({ error => "User must be defined." }, 500);
        }

        die $_ unless blessed $_ && $_->can('rethrow');
        if ($_->isa('Koha::Exceptions::Password::Invalid')) {
            return $c->$cb({ error => "Wrong current password." }, 400);
        }
        elsif ($_->isa('Koha::Exceptions::Password::TooShort')) {
            return $c->$cb({ error => $_->error }, 400);
        }
        elsif ($_->isa('Koha::Exceptions::Password::TrailingWhitespaces')) {
            return $c->$cb({ error => $_->error }, 400);
        }
        elsif ($_->isa('Koha::Exceptions::BadSystemPreference')
               && $_->preference eq 'OpacPasswordChange') {
            return $c->$cb({ error => "OPAC password change is disabled" }, 403);
        }
        else {
            return $c->$cb({ error => "Something went wrong. $_" }, 500);
        }
    }
}

1;
