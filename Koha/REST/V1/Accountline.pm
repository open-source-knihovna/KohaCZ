package Koha::REST::V1::Accountline;

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

use C4::Auth qw( haspermission );
use C4::Accounts qw( makepayment makepartialpayment recordpayment );
use C4::Members qw( GetMember );
use Koha::Accountlines;
use Scalar::Util qw( looks_like_number );

sub list {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');
    unless ($user && haspermission($user->userid, {updatecharges => 1})) {
        return $c->$cb({error => "You don't have the required permission"}, 403);
    }

    my $params  = $c->req->params->to_hash;
    my $accountlines = Koha::Accountlines->search($params);

    return $c->$cb($accountlines->unblessed, 200);
}


sub edit {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');
    unless ($user && haspermission($user->userid, {updatecharges => 1})) {
        return $c->$cb({error => "You don't have the required permission"}, 403);
    }

    my $accountline = Koha::Accountlines->find($args->{accountlines_id});
    unless ($accountline) {
        return $c->$cb({error => "Accountline not found"}, 404);
    }

    my $body = $c->req->json;

    $accountline->set( $body );
    $accountline->store();

    return $c->$cb($accountline->unblessed(), 200);
}


sub pay {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');
    unless ($user && haspermission($user->userid, {updatecharges => 1})) {
        return $c->$cb({error => "You don't have the required permission"}, 403);
    }

    my $accountline = Koha::Accountlines->find($args->{accountlines_id});
    unless ($accountline) {
        return $c->$cb({error => "Accountline not found"}, 404);
    }

    makepayment($accountline->accountlines_id,
                $accountline->borrowernumber,
                $accountline->accountno,
                $accountline->amount);

    $accountline = Koha::Accountlines->find($args->{accountlines_id});
    return $c->$cb($accountline->unblessed(), 200);
}

sub partialpay {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');
    unless ($user && haspermission($user->userid, {updatecharges => 1})) {
        return $c->$cb({error => "You don't have the required permission"}, 403);
    }

    my $accountline = Koha::Accountlines->find($args->{accountlines_id});
    unless ($accountline) {
        return $c->$cb({error => "Accountline not found"}, 404);
    }

    my $body = $c->req->json;
    my $amount = $body->{amount};
    my $note = $body->{note} || '';

    unless ($amount && looks_like_number($amount)) {
        return $c->$cb({error => "Invalid amount"}, 400);
    }

    makepartialpayment($accountline->accountlines_id,
                       $accountline->borrowernumber,
                       $accountline->accountno,
                       $amount, '', '', $note);

    $accountline = Koha::Accountlines->find($args->{accountlines_id});
    return $c->$cb($accountline->unblessed(), 200);
}


sub payamount   {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');
    unless ($user && haspermission($user->userid, {updatecharges => 1})) {
        return $c->$cb({error => "You don't have the required permission"}, 403);
    }

    my $borrower = GetMember(borrowernumber => $args->{borrowernumber});
    unless ($borrower) {
        return $c->$cb({error => "Borrower not found"}, 404);
    }

    my $body = $c->req->json;
    my $amount = $body->{amount};
    my $note = $body->{note} || '';

    unless ($amount && looks_like_number($amount)) {
        return $c->$cb({error => "Invalid amount"}, 400);
    }

    recordpayment($borrower->{borrowernumber}, $amount, '', $note);

    return $c->$cb({amount => $amount}, 200);
}

1;
