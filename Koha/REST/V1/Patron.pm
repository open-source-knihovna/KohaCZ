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
use Koha::Account;

use Scalar::Util qw(blessed looks_like_number);
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
    my $c = shift->openapi->valid_input or return;

    my $borrowernumber = $c->validation->param('borrowernumber');

    my $patron;
    try {
        $patron = Koha::Patrons->find($borrowernumber);

        my $OpacPasswordChange = C4::Context->preference("OpacPasswordChange");
        unless ($OpacPasswordChange) {
            Koha::Exceptions::BadSystemPreference->throw(
                preference => 'OpacPasswordChange'
            );
        }

        my $pw = $c->req->json;

	warn "current password" . $pw->{'current_password'} . ";";
	warn "new password" . $pw->{'new_password'} . ";";
        my $dbh = C4::Context->dbh;
        unless (checkpw_internal($dbh, $patron->userid, $pw->{'current_password'})) {
            Koha::Exceptions::Password::Invalid->throw;
        }
        $patron->change_password_to($pw->{'new_password'});
        return $c->render( status => 200, openapi => {} );
    }
    catch {
        if (not defined $patron) {
            return $c->render( status => 404, openapi => { error => "Patron not found." } );
        }

        die $_ unless blessed $_ && $_->can('rethrow');
        if ($_->isa('Koha::Exceptions::Password::Invalid')) {
            return $c->render( status =>  400, openapi => { error => "Wrong current password." } );
        }
        elsif ($_->isa('Koha::Exceptions::Password::TooShort')) {
            return $c->render( status => 400, openapi => { error => $_->error } );
        }
        elsif ($_->isa('Koha::Exceptions::Password::TrailingWhitespaces')) {
            return $c->render( status => 400, openapi => { error => $_->error } );
        }
        elsif ($_->isa('Koha::Exceptions::BadSystemPreference')
               && $_->preference eq 'OpacPasswordChange') {
            return $c->render( status => 403, openapi =>  { error => "OPAC password change is disabled" } );
        }
        else {
            return $c->render( status => 500, openapi => { error => "Something went wrong. $_" } );
        }
    }
}

sub pay {
    my $c = shift->openapi->valid_input or return;

    my $args = $c->req->params->to_hash // {};

    my $borrowernumber = $c->validation->param('borrowernumber');

    return try {
        my $patron = Koha::Patrons->find($borrowernumber);
        unless ($patron) {
            return $c->render( status => 404, openapi => {error => "Patron $borrowernumber not found" } );
        }

        my $body = $c->req->json;
        my $amount = $body->{amount};
        my $note = $body->{note} || '';

        Koha::Account->new(
            {
                patron_id => $borrowernumber,
            }
          )->pay(
            {
                amount => $amount,
                note => $note,
            }
          );

        return $c->render( status => 204, openapi => {} );
    } catch {
        if ($_->isa('DBIx::Class::Exception')) {
            return $c->render( status => 500, openapi => { error => $_->msg } );
        } else {
            return $c->render( status => 500, openapi => {
                error => 'Something went wrong, check the logs.'
            } );
        }
    };
}

1;
