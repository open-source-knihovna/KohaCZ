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

use C4::Output;
use C4::Auth;
use C4::Context;
use C4::Items;
use C4::Biblio;
use C4::Circulation;

use Koha::Items;
use Koha::RotatingCollections;

use CGI qw ( -utf8 );

my $query = new CGI;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "rotating_collections/addItems.tt",
        query           => $query,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { tools => 'rotating_collections' },
        debug           => 1,
    }
);

my @errors;
my @messages;
my $colId = $query->param('colId');
my $collection = Koha::RotatingCollections->find($colId);

my $action = $query->param('action') || '';

if ( $action eq 'addItem' ) {
    ## Add the given item to the collection
    my $barcode    = $query->param('barcode');
    my $removeItem = $query->param('removeItem');
    my $item       = Koha::Items->find( { barcode => $barcode } );

    my ( $success, $errorCode, $errorMessage );
    my $libraryName;

    $template->param( barcode => $barcode );
    $template->param( item => $item );

    if ( !$removeItem ) {
        my $added = eval { $collection->add_item( $item ) };

        if ( $@ or not $added ) {
            push @errors, { code => 'error_adding_item' };
        } else {
            push @messages, { code => 'success_adding_item' };
        }
    } else {
        ## Remove the given item from the collection
        my $deleted = eval { $collection->remove_item( $item ) };
        my ($doreturn, $messages, $iteminformation, $borrower);

        if ( $item->checkout ) {
          $template->param( returnNote => "ITEM_ISSUED" );
          AddReturn($barcode);
        }

        if ( $@ or not $deleted ) {
            push @errors, { code => 'error_removing_item' };
        } else {
            push @messages, { code => 'success_removing_item' };
            my $hold_library = Koha::RotatingCollections->get_hold_from_lists($item);
            $template->param( hold_library => $hold_library );
        }

        $template->param(
            removeChecked => 1,
        );
    }
}

$template->param(
    collection => $collection,
    messages   => \@messages,
    errors     => \@errors,
);

output_html_with_http_headers $query, $cookie, $template->output;
