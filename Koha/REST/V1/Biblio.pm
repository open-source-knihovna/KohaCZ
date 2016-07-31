package Koha::REST::V1::Biblio;

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

use strict;
use warnings;

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use C4::Auth qw( haspermission );
use C4::Context;
use C4::Items qw( GetItem GetHiddenItemnumbers );

use Koha::Biblios;
use Koha::Items;

sub get {
    my ($c, $args, $cb) = @_;

    my $biblionumber = $c->param('biblionumber');
    my $biblio = Koha::Biblios->find($biblionumber);

    unless ($biblio) {
      return $c->$cb({error => "Biblio not found"}, 404);
    }

    my $items ||= Koha::Items->search( { biblionumber => $biblionumber }, {
      columns => [qw/itemnumber/],
    })->unblessed;

    my $user = $c->stash('koha.user');
    my $isStaff = haspermission($user->userid, {borrowers => 1});

    # Hide the hidden items from all but staff
    my $opachiddenitems = ! $isStaff
      && ( C4::Context->preference('OpacHiddenItems') !~ /^\s*$/ );

    if ($opachiddenitems) {

      my @hiddenitems = C4::Items::GetHiddenItemnumbers( @{$items} );

      my @filteredItems = ();

      # Convert to a hash for quick searching
      my %hiddenitems = map { $_ => 1 } @hiddenitems;
      foreach my $itemnumber ( map { $_->{itemnumber} } @{$items} ) {
          next if $hiddenitems{$itemnumber};
          push @filteredItems, { itemnumber => $itemnumber };
      }

      $items = \@filteredItems;
    }

    $biblio = $biblio->unblessed;
    $biblio->{items} = $items;

    return $c->$cb($biblio, 200);
}

1;
