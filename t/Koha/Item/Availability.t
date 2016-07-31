#!/usr/bin/perl

# Copyright KohaSuomi 2016
#
# This file is part of Koha
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
use Test::More tests => 16;

use_ok('Koha::Item::Availability');

my $availability = Koha::Item::Availability->new->set_available;

is($availability->{available}, 1, "Available");
$availability->set_needs_confirmation;
is($availability->{availability_needs_confirmation}, 1, "Needs confirmation");
$availability->set_unavailable;
is($availability->{available}, 0, "Not available");

$availability->add_description("such available");
$availability->add_description("wow");
$availability->add_description("wow");

ok($availability->has_description("wow"), "Found description 'wow'");
ok($availability->has_description(["wow", "such available"]),
   "Found description 'wow' and 'such available'");
is($availability->has_description(["wow", "much not found"]), 0,
   "Didn't find 'wow' and 'much not found'");
is($availability->{description}[0], "such available",
   "Found correct description in correct index 1/4");
is($availability->{description}[1], "wow",
   "Found correct description in correct index 2/2");

$availability->add_description(["much description", "very doge"]);
is($availability->{description}[2], "much description",
   "Found correct description in correct index 3/4");
is($availability->{description}[3], "very doge",
   "Found correct description in correct index 4/4");

$availability->del_description("wow");
is($availability->{description}[1], "much description",
   "Found description from correct index after del");
$availability->del_description(["very doge", "such available"]);
is($availability->{description}[0], "much description",
   "Found description from correct index after del");


my $availability_clone = $availability;
$availability->set_unavailable;
is($availability_clone->{available}, $availability->{available},
   "Availability_clone points to availability");
$availability_clone = $availability->clone;
$availability->set_available;
isnt($availability_clone->{available}, $availability->{available},
     "Availability_clone was cloned and no longer has same availability status");

$availability->reset;
is($availability->{available}, undef, "Availability reset");
