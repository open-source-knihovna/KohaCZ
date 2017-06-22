package Koha::PosTerminal::Message::Header;

# Copyright 2017 R-Bit Technology, s.r.o.
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

use strict;
use warnings;

use DateTime qw();

use constant SPC => ' ';
use constant PROTOCOL_TYPE => "B1";
use constant PROTOCOL_VERSION => "01";
use constant TIMEZONE => "Europe/Prague";
use constant CRC_NO_DATA => "A5A5";
use constant NO_DATA_LENGTH => "0000";
use constant TAGS_EMPTY => "0000";
use constant TAGS_SIGNATURE_CHECK => 0x0001;

use base qw(Class::Accessor);
Koha::PosTerminal::Message::Header->mk_accessors(qw(protocolType protocolVersion terminalID dateTime tags length crc));

sub new {
   my $class = shift @_;

   my $self = $class->SUPER::new(@_);
   $self->protocolType(PROTOCOL_TYPE);
   $self->protocolVersion(PROTOCOL_VERSION);
   $self->terminalID(0);
   $self->dateTime(0);
   $self->tags(TAGS_EMPTY);
   $self->length(NO_DATA_LENGTH);
   $self->crc(CRC_NO_DATA);

   return $self;
}

sub terminalID {
        my($self) = shift;

        if( @_ ) {  # Setting
            my($terminalID) = @_;

            if (!$terminalID) {
                $terminalID = " " x 8;
            }
            return $self->set('terminalID', $terminalID);
        }
        else {
            return $self->get('terminalID');
        }
}

sub dateTime {
        my($self) = shift;

        if( @_ ) {  # Setting
            my($dateTime) = @_;

            if (!$dateTime) {
                my $dt = DateTime->now(time_zone => TIMEZONE);
                $dateTime = $dt->strftime('%y%m%d%H%M%S');
            }
            return $self->set('dateTime', $dateTime);
        }
        else {
            return $self->get('dateTime');
        }
}

sub isSignatureCheckRequired {
    my( $self ) = @_;
    return hex("0x" . $self->tags) & TAGS_SIGNATURE_CHECK;
}

sub getContent {
    my( $self ) = @_;
    my $content =
          $self->protocolType
        . $self->protocolVersion
        . $self->terminalID
        . $self->dateTime
        . $self->tags
        . $self->length
        . $self->crc;
    return $content;
}

sub dumpObject {
    my( $self ) = @_;
    my @dt = ( $self->dateTime =~ m/../g );
    my $obj =
          "protocol:\n"
        . "  type: '".$self->protocolType."'\n"
        . "  version: '".$self->protocolVersion."'\n"
        . "terminal ID: '".$self->terminalID."'\n"
        . "date:\n"
        . "  year: '".$dt[0]."'\n"
        . "  month: '".$dt[1]."'\n"
        . "  day: '".$dt[2]."'\n"
        . "time:\n"
        . "  hours: '".$dt[3]."'\n"
        . "  minutes: '".$dt[4]."'\n"
        . "  seconds: '".$dt[5]."'\n"
        . "tags: '".$self->tags."'\n"
        . "length: '".$self->length."'\n"
        . "crc: '".$self->crc."'\n";

    return $obj;
}

1;