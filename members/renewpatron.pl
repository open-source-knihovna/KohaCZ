#!/usr/bin/perl
#script to renew patron membership
#written 17/1/2015
#by josef.moravec@gmail.com


# Copyright 2015 Josef MOravec
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use strict;
use warnings;

use CGI qw ( -utf8 );
use C4::Context;
use C4::Members;
use C4::Auth;
use Koha::DateUtils;

my $input = new CGI;

checkauth($input, 0, { borrowers => 1 }, 'intranet');

my $destination = $input->param("destination") || '';
my $borrowernumber=$input->param('borrowernumber');
my $cardnumber = $input->param("cardnumber");
my $dbh = C4::Context->dbh;
my $dateexpiry;

my $borrower = GetMemberDetails( $borrowernumber, '');

my $date = $borrower->{'dateexpiry'};
my $today = output_pref({ dt => dt_from_string, dateformat => 'iso', dateonly => 1 });
$date = ($date gt $today) ? $date : $today;
$date = GetExpiryDate( $borrower->{'categorycode'}, $date );

$dateexpiry = ExtendMemberSubscriptionTo( $borrowernumber , $date );

if($destination eq "circ") {
    print $input->redirect("/cgi-bin/koha/circ/circulation.pl?borrowernumber=$borrowernumber&was_renewed=1");
} else {
    print $input->redirect("/cgi-bin/koha/members/moremember.pl?borrowernumber=$borrowernumber&was_renewed=1");
}
