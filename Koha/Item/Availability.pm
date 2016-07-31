package Koha::Item::Availability;

# Copyright KohaSuomi 2016
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

use Storable qw(dclone);

=head1 NAME

Koha::Item::Availability - Koha Item Availability object class

=head1 SYNOPSIS

  my $item = Koha::Items->find(1337);
  my $availabilities = $item->availabilities();
  # ref($availabilities) eq 'HASH'
  # ref($availabilities->{'checkout'}) eq 'Koha::Item::Availability'

  print "Available for checkout!" if $availabilities->{'checkout'}->{available};

=head1 DESCRIPTION

This class holds item availability information.

See Koha::Item for availability subroutines.

=head2 Class Methods

=cut

=head3 new

Returns a new Koha::Item::Availability object.

=cut

sub new {
    my ( $class ) = @_;

    my $self = {
        description        => [],
        availability_needs_confirmation => undef,
        available                       => undef,
        expected_available              => undef,
    };

    bless( $self, $class );
}

=head3 add_description

$availability->add_description("notforloan");
$availability->add_description("withdrawn);

# $availability->{description} = ["notforloan", "withdrawn"]

Pushes a new description to $availability object. Does not duplicate existing
descriptions.

Returns updated Koha::Item::Availability object.

=cut

sub add_description {
    my ($self, $description) = @_;

    return $self unless $description;

    if (ref($description) eq 'ARRAY') {
        foreach my $desc (@$description) {
            if (grep(/^$desc$/, @{$self->{description}})){
                next;
            }
            push $self->{description}, $desc;
        }
    } else {
        if (!grep(/^$description$/, @{$self->{description}})){
            push $self->{description}, $description;
        }
    }

    return $self;
}

=head3 clone

$availability_cloned = $availability->clone;
$availability->set_unavailable;

# $availability_cloned->{available} != $availability->{available}

Clones the Koha::Item::Availability object.

Returns cloned object.

=cut

sub clone {
    my ( $self ) = @_;

    return dclone($self);
}

=head3 del_description

$availability->add_description(["notforloan", "withdrawn", "itemlost", "restricted"]);
$availability->del_description("withdrawn");

# $availability->{description} == ["notforloan", "itemlost", "restricted"]
$availability->del_description(["withdrawn", "restricted"]);
# $availability->{description} == ["itemlost"]

Deletes an availability description(s) if it exists.

Returns (possibly updated) Koha::Item::Availability object.

=cut

sub del_description {
    my ($self, $description) = @_;

    return $self unless $description;

    my @updated;
    if (ref($description) eq 'ARRAY') {
        foreach my $desc (@$description) {
            @updated = grep(!/^$desc$/, @{$self->{description}});
        }
    } else {
        @updated = grep(!/^$description$/, @{$self->{description}});
    }
    $self->{description} = \@updated;

    return $self;
}

=head3 hash_description

$availability->add_description(["notforloan", "withdrawn"]);
$availability->has_description("withdrawn"); # 1
$availability->has_description(["notforloan", "withdrawn"]); # 1
$availability->has_description("itemlost"); # 0

Finds description(s) in availability descriptions.

Returns 1 if found, 0 otherwise.

=cut

sub has_description {
    my ($self, $description) = @_;

    return 0 unless $description;

    my @found;
    if (ref($description) eq 'ARRAY') {
        foreach my $desc (@$description) {
            if (!grep(/^$desc$/, @{$self->{description}})){
                return 0;
            }
        }
    } else {
        if (!grep(/^$description$/, @{$self->{description}})){
            return 0;
        }
    }

    return 1;
}

=head3 reset

$availability->reset;

Resets the object.

=cut

sub reset {
    my ( $self ) = @_;

    $self->{available} = undef;
    $self->{availability_needs_confirmation} = undef;
    $self->{expected_available} = undef;
    $self->{description} = [];
    return $self;
}

=head3 set_available

$availability->set_available;

Sets the Koha::Item::Availability object status to available.
   $availability->{available} == 1

Overrides old availability status, but does not override other stored data in
the object. Create a new Koha::Item::Availability object to get a fresh start.
Appends any previously defined availability descriptions with add_description().

Returns updated Koha::Item::Availability object.

=cut

sub set_available {
    my ($self, $description) = @_;

    return $self->_update_availability_status(1, 0, $description);
}

=head3 set_needs_confirmation

$availability->set_needs_confirmation("unbelieveable_reason", "2016-07-07");

Sets the Koha::Item::Availability object status to unavailable,
but needs confirmation.
   $availability->{available} == 0
   $availability->{availability_needs_confirmation} == 1

Overrides old availability statuses, but does not override other stored data in
the object. Create a new Koha::Item::Availability object to get a fresh start.
Appends any previously defined availability descriptions with add_description().
Allows you to define expected availability date in C<$expected>.

Returns updated Koha::Item::Availability object.

=cut

sub set_needs_confirmation {
    my ($self, $description, $expected) = @_;

    return $self->_update_availability_status(0, 1, $description, $expected);
}

=head3 set_unavailable

$availability->set_unavailable("onloan", "2016-07-07");

Sets the Koha::Item::Availability object status to unavailable.
   $availability->{available} == 0

Overrides old availability status, but does not override other stored data in
the object. Create a new Koha::Item::Availability object to get a fresh start.
Appends any previously defined availability descriptions with add_description().
Allows you to define expected availability date in C<$expected>.

Returns updated Koha::Item::Availability object.

=cut

sub set_unavailable {
    my ($self, $description, $expected) = @_;

    return $self->_update_availability_status(0, 0, $description, $expected);
}

sub _update_availability_status {
    my ( $self, $available, $needs, $desc, $expected ) = @_;

    $self->{available} = $available;
    $self->{availability_needs_confirmation} = $needs;
    $self->{expected_available} = $expected if $expected;
    $self->add_description($desc);

    return $self;
}

1;
