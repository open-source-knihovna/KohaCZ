#!/usr/bin/perl

# This file is part of Koha.
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
#

use Modern::Perl;

use CGI qw ( -utf8 );

use C4::Output;
use C4::Auth;
use C4::Context;
use C4::RotatingCollections;

use Koha::RotatingCollections;

my $query = new CGI;
my $action = $query->param('action');
my @messages;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "rotating_collections/editCollections.tt",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'rotating_collections' },
        debug           => 1,
    }
);

# Create new Collection
if ( $action eq 'create' ) {
    my $title       = $query->param('title');
    my $description = $query->param('description');

    my ( $createdSuccessfully, $errorCode, $errorMessage ) =
      CreateCollection( $title, $description );

    $template->param(
        previousActionCreate => 1,
        createdTitle         => $title,
    );

    if ($createdSuccessfully) {
        $template->param( createSuccess => 1 );
    }
    else {
        $template->param( createFailure  => 1 );
        $template->param( failureMessage => $errorMessage );
    }
} elsif ( $action eq 'delete' ) { # Delete collection
    my $colId = $query->param('colId');
    my $collection = Koha::RotatingCollections->find($colId);
    my $deleted = eval { $collection->delete; };

    if ( $@ or not $deleted ) {
        push @messages, { type => 'error', code => 'error_on_delete' };
    } else {
        push @messages, { type => 'message', code => 'success_on_delete' };
    }
    $action = "list";
}

## Edit a club or service: grab data, put in form.
elsif ( $action eq 'edit' ) {
    my $collection = Koha::RotatingCollections->find($query->param('colId'));

    $template->param(
        previousActionEdit => 1,
        editColId          => $collection->{colId},
        editColTitle       => $collection->{colTitle},
        editColDescription => $collection->{colDesc},
    );
}

# Update a Club or Service
elsif ( $action eq 'update' ) {
    my $colId       = $query->param('colId');
    my $title       = $query->param('title');
    my $description = $query->param('description');

    my ( $createdSuccessfully, $errorCode, $errorMessage ) =
      UpdateCollection( $colId, $title, $description );

    $template->param(
        previousActionUpdate => 1,
        updatedTitle         => $title,
    );

    if ($createdSuccessfully) {
        $template->param( updateSuccess => 1 );
    }
    else {
        $template->param( updateFailure  => 1 );
        $template->param( failureMessage => $errorMessage );
    }
}

$template->param(
    action   => $action,
    messages => \@messages,
);

output_html_with_http_headers $query, $cookie, $template->output;
