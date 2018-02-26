#!/usr/bin/perl

#written 11/1/2000 by chris@katipo.oc.nz
#script to display borrowers account details


# Copyright 2000-2002 Katipo Communications
# Copyright 2010 BibLibre
#
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

use Modern::Perl;

use C4::Auth;
use C4::Output;
use CGI qw ( -utf8 );
use C4::Accounts;

use Koha::Items;

my $input = new CGI;
my $flagsrequired = { borrowers => 1, updatecharges => 'remaining_permissions' };

my $borrowernumber=$input->param('borrowernumber');

# get borrower details
my $add = $input->param('add');
if ($add){
    if ( checkauth( $input, 0, $flagsrequired, 'intranet' ) ) {
        #  print $input->header;
        my $barcode = $input->param('barcode');
        my $item = Koha::Items->find({ barcode => $barcode });
        my $itemnumber;
        if ($item) {
            $itemnumber = $item->itemnumber;
        }
        my $desc = $input->param('desc');
        my $amount = $input->param('amount');
        my $type = $input->param('type');
        my $error = manualinvoice( $borrowernumber, $itemnumber, $desc, $type, $amount );
    }
}
print $input->redirect("/cgi-bin/koha/members/boraccount.pl?borrowernumber=$borrowernumber");
exit;

