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

use Koha::Patrons;

sub list {
    my ($c, $args, $cb) = @_;

    my $params = $c->req->query_params->to_hash;
    my @valid_params = Koha::Patrons->_resultset->result_source->columns;
    foreach my $key (keys %$params) {
        delete $params->{$key} unless grep { $key eq $_ } @valid_params;
    }
    my $patrons = Koha::Patrons->search($params);

    return $c->$cb($patrons, 200);
}

sub get {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');

    my $patron = Koha::Patrons->find($args->{borrowernumber});
    unless ($patron) {
        return $c->$cb({error => "Patron not found"}, 404);
    }

    return $c->$cb($patron, 200);
}

1;
