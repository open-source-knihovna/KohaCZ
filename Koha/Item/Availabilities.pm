package Koha::Item::Availabilities;

# Copyright Koha-Suomi Oy 2016
#
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

use Modern::Perl;

use C4::Context;
use C4::Reserves;

use Koha::Exceptions;
use Koha::Issues;
use Koha::Item::Availability;
use Koha::Items;
use Koha::ItemTypes;

=head1 NAME

Koha::Item::Availabilities - Koha Item Availabilities object class

=head1 SYNOPSIS

  my $availabilities = Koha::Items->find(1337)->availabilities;

  print "Available for checkout!" if $availabilities->checkout->available;

=head1 DESCRIPTION

This class holds logic for calculating different types of availabilities.

=head2 Class Methods

=cut

=head3 new

=cut

sub new {
    my ($class, $params) = @_;

    my $self = {};
    my $item;

    unless(ref($params) eq 'Koha::Item') {
        Koha::Exceptions::MissingParameter->throw({
            error => "Missing parameter itemnumber",
            parameter => "itemnumber",
        }) unless $params->{'itemnumber'};

        $item = Koha::Items->find($params->{'itemnumber'});
    } else {
        $item = $params;
    }

    $self->{'item'} = $item;
    $self->{'_use_stored_values'} = 0;

    bless($self, $class);
}

=head3 hold

Availability for holds. Does not consider patron status.

=cut

sub hold {
    my ($self) = @_;

    my $item = $self->item;
    my $availability = Koha::Item::Availability->new->set_available;

    $availability->set_unavailable("withdrawn") if $item->withdrawn;
    $availability->set_unavailable("itemlost") if $item->itemlost;
    $availability->set_unavailable("restricted") if $item->restricted;

    if ($item->damaged) {
        if (C4::Context->preference('AllowHoldsOnDamagedItems')) {
            $availability->add_description("damaged");
        } else {
            $availability->set_unavailable("damaged");
        }
    }

    my $itemtype;
    if (C4::Context->preference('item-level_itypes')) {
        $itemtype = Koha::ItemTypes->find($item->itype);
    } else {
        my $biblioitem = Koha::Biblioitems->find($item->biblioitemnumber );
        $itemtype = Koha::ItemTypes->find($biblioitem->itemtype);
    }

    if ($item->notforloan > 0 || $itemtype && $itemtype->notforloan) {
        $availability->set_unavailable("notforloan");
    } elsif ($item->notforloan < 0) {
        $availability->set_unavailable("ordered");
    }

    $self->{'_hold'} = $availability;
    return $availability;
}

=head3 issue

Availability for checkouts. Does not consider patron status.

=cut

sub issue {
    my ($self, $params) = @_;

    my $item = $self->item;
    my $availability;
    unless ($self->use_stored_values) {
        $availability = $self->hold->clone;
    }
    else {
        if ($self->{'_hold'}) {
            $availability = $self->{'_hold'}->clone;
        } else {
            $availability = $self->hold->clone;
        }
    }

    if (my $issue = Koha::Issues->find({ itemnumber => $item->itemnumber })) {
        $availability->set_unavailable("onloan", $issue->date_due);
    }

    if (C4::Reserves::CheckReserves($item->itemnumber)) {
        $availability->set_unavailable("reserved");
    }

    $self->{'_issue'} = $availability;
    return $availability;
}

=head3 item

=cut

sub item {
    my ($self) = @_;

    return $self->{'item'};
}

=head3 local_use

Same as checkout availability, but exclude notforloan.

=cut

sub local_use {
    my ($self) = @_;

    my $availability;
    unless ($self->use_stored_values) {
        $availability = $self->issue->clone;
    }
    else {
        if ($self->{'_issue'}) {
            $availability = $self->{'_issue'}->clone;
        } else {
            $availability = $self->issue->clone;
        }
    }

    if (grep(/^notforloan$/, @{$availability->description})
        && @{$availability->description} == 1) {
        $availability = $availability->set_available;
    }
    $availability->del_description("notforloan");

    $self->{'_local_use'} = $availability;
    return $availability;
}

=head3 onsite_checkout

Same as local_use availability, but consider OnSiteCheckouts system preference.

=cut

sub onsite_checkout {
    my ($self) = @_;

    my $availability;
    unless ($self->use_stored_values) {
        $availability = $self->local_use->clone;
    }
    else {
        if ($self->{'_local_use'}) {
            $availability = $self->{'_local_use'}->clone;
        } else {
            $availability = $self->local_use->clone;
        }
    }

    if (!C4::Context->preference('OnSiteCheckouts')) {
        $availability = Koha::Item::Availability->new
        ->set_unavailable("onsite_checkouts_disabled");
    }

    $self->{'_onsite_checkout'} = $availability;
    return $availability;
}

=head3 use_stored_values

ON: $availabilities->use_stored_values(1);
OFF: $availabilities->use_stored_values(0);

Performance enhancement.

Different availability types are dependent on some others. For example issues
are dependent on holds; if holds are unavailable, so are issues. If we want to
gather all types of availabilities in one go, we can store the previous
availability in the object and use it for the next one without re-calculating
the previous availabilities.

This is the purpose of this switch; when enabled, use stored availability in
the object for availability dependencies. When disabled, always re-calculate
dependencies as well.

=cut

sub use_stored_values {
    my ($self, $use_stored_values) = @_;

    if (defined $use_stored_values) {
        $self->{'_use_stored_values'} =
        $use_stored_values ? 1 : 0;
    }

    return $self->{'_use_stored_values'};
}

1;
