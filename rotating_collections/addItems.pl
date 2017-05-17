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

if ( $query->param('action') eq 'addItem' ) {
    ## Add the given item to the collection
    my $barcode    = $query->param('barcode');
    my $removeItem = $query->param('removeItem');
    my $itemnumber = GetItemnumberFromBarcode($barcode);

    my ( $success, $errorCode, $errorMessage );

    $template->param( barcode => $barcode );

    if ( !$removeItem ) {
        my $added = eval { $collection->add_item( $itemnumber ) };

        if ( $@ or not $added ) {
            push @errors, { code => 'error_adding_item' };
        } else {
            push @messages, { code => 'success_adding_item' };
        }
    } else {
        ## Remove the given item from the collection
        my $deleted = eval { $collection->remove_item( $itemnumber ) };

        if ( $@ or not $deleted ) {
            push @errors, { code => 'error_removing_item' };
        } else {
            push @messages, { code => 'success_removing_item' };
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
