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
use C4::Members;
use C4::Accounts;
use C4::Items;
use C4::Members::Attributes qw(GetBorrowerAttributes);

use Koha::Patrons;
use Koha::Patron::Images;
use Koha::Patron::Categories;
use Koha::Account::DebitTypes;
use Koha::Account::CreditTypes;

my $input=new CGI;
my $flagsrequired = { borrowers => 1, updatecharges => 'remaining_permissions' };

my $borrowernumber=$input->param('borrowernumber');

my $patron = Koha::Patrons->find( $borrowernumber );
unless ( $patron ) {
    print $input->redirect("/cgi-bin/koha/circ/circulation.pl?borrowernumber=$borrowernumber");
    exit;
}

my $add=$input->param('add');
if ($add){
    if ( checkauth( $input, 0, $flagsrequired, 'intranet' ) ) {
        #  print $input->header;
        my $barcode=$input->param('barcode');
        my $itemnum;
        if ($barcode) {
            $itemnum = GetItemnumberFromBarcode($barcode);
        }
        my $desc=$input->param('desc');
        my $amount=$input->param('amount');
        my $type=$input->param('type');
        my $error   = manualinvoice( $borrowernumber, $itemnum, $desc, $type, $amount );
    }
}
print $input->redirect("/cgi-bin/koha/members/boraccount.pl?borrowernumber=$borrowernumber");
exit;

