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

use Koha::RotatingCollections;

my $query = new CGI;
my $action = $query->param('action');
my @messages;
my @errors;

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
    $template->param( createdTitle => $title );

    my $collection = Koha::RotatingCollection->new(
        {   colTitle => $title,
            colDesc  => $description,
        }
    );

    eval { $collection->store; };

    if ($@) {
        push @errors, { code => 'error_on_insert' };
    } else {
        push @messages, { code => 'success_on_insert' };
    }

} elsif ( $action eq 'delete' ) { # Delete collection
    my $colId = $query->param('colId');
    my $collection = Koha::RotatingCollections->find($colId);
    my $deleted = eval { $collection->delete; };

    if ( $@ or not $deleted ) {
        push @errors, { code => 'error_on_delete' };
    } else {
        push @messages, { code => 'success_on_delete' };
    }

} elsif ( $action eq 'edit' ) { # Edit page of collection
    my $collection = Koha::RotatingCollections->find($query->param('colId'));

    $template->param(
        previousActionEdit => 1,
        collection         => $collection,
    );

} elsif ( $action eq 'update' ) { # Update collection
    my $colId       = $query->param('colId');
    my $title       = $query->param('title');
    my $description = $query->param('description');

    $template->param( updatedTitle => $title );

    if ($colId) {
        my $collection = Koha::RotatingCollections->find($colId);
        $collection->colTitle($title);
        $collection->colDesc($description);

        eval { $collection->store; };

        if ($@) {
            push @errors, { code => 'error_on_update' };
        } else {
            push @messages, { code => 'success_on_update' };
        }
    }
}

$template->param(
    action   => $action,
    messages => \@messages,
    errors   => \@errors,
);

output_html_with_http_headers $query, $cookie, $template->output;
