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
use C4::Circulation;

use Koha::Items;
use Koha::RotatingCollections;

my $query = new CGI;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "rotating_collections/rotatingCollections.tt",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'rotating_collections' },
        debug           => 1,
    }
);

my $action = $query->param('action') || '';

if ( $action eq 'removeItem' ) {
    my $barcode = $query->param('barcode');
    my $item = Koha::Items->find({ barcode => $barcode });
    if ( $item ) {
        if ( $item->checkout ) {
            $template->param( returnNote => "ITEM_ISSUED" );
            AddReturn($barcode);
        }

        $template->param( barcode => $barcode );
        $template->param( item => $item );

        my $collection = $item->rotating_collection;
        if ($collection) {
            $collection->remove_item($item);
            $template->param( removeSuccess => 1 );
        } else {
            $template->param( removeFailure  => 1 );
            $template->param( failureMessage => "NOT_IN_COLLECTION" );
        }
    } else {
        $template->param( removeFailure => 1 );
        $template->param( failureMessage => "ITEM_NOT_FOUND" );
    }
}

my $collections = Koha::RotatingCollections->search;

$template->param(
    collectionsLoop => $collections,
);

output_html_with_http_headers $query, $cookie, $template->output;
