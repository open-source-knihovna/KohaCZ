package Koha::PosTerminal::Message;

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

use Digest::CRC;
use Koha::PosTerminal::Message::Header;
use Koha::PosTerminal::Message::Field;
use Data::Dumper qw( Dumper );

use constant {
    STX => "\x02",
    ETX => "\x03",
    FS  => "\x1C",
    GS  => "\x1D",
    CR  => "\x0D",
    LF  => "\x0A"
};

use constant {
    F_PAID_AMOUNT       => "B",
    F_CURRENCY_CODE     => "I",
    F_TRANSACTION_TYPE  => "T",
    F_RESPONSE_CODE     => "R",
    F_CARD_NUMBER       => "P",
    F_CARD_PRODUCT      => "J",
    F_INVOICE_NUMBER    => "S",
    F_CODE_PAGE         => "f",
    F_RECEIPT           => "t",
    F_TRANSACTION_ID    => "n",
    F_APPLICATION_ID    => "a"
};

use constant {
    TTYPE_SALE                      => "00",
    TTYPE_PREAUTH                   => "01",
    TTYPE_PREAUTH_COMPLETION        => "02",
    TTYPE_REVERSAL                  => "10",
    TTYPE_REFUND                    => "04",
    TTYPE_ABORT                     => "12",
    TTYPE_POST_DATA_PRINTING        => "16",
    TTYPE_REPEAT_LAST_TRANSACTION   => "17"
};

use constant {
    DIR_SENT  => "SENT",
    DIR_RECEIVED => "RCVD"
};

sub new {
    my $class  = shift;

    my $self = {};
    $self->{_header} = Koha::PosTerminal::Message::Header->new();
    $self->{_fields} = ();
    $self->{_isValid} = 0;
    $self->{_direction} = shift;

    bless $self, $class;
    return $self;
}

sub getDirection {
    my( $self ) = @_;
    return $self->{_direction};
}

sub getHeader {
    my( $self ) = @_;
    return $self->{_header};
}

sub getContent {
    my( $self ) = @_;

    my $msg = $self->getHeader()->getContent();
    foreach my $field (@{$self->{_fields}}) {
        $msg .= FS.$field->name.$field->value;
    }

    return STX.$msg.ETX;
}

sub addField {
    my ( $self, $fieldName, $value ) = @_;
    my $field = Koha::PosTerminal::Message::Field->new({ name => $fieldName, value => $value });
    push(@{$self->{_fields}}, $field);
    $self->updateHeader();
}

sub getField {
    my ( $self, $fieldName ) = @_;
    foreach my $field (@{$self->{_fields}}) {
        if ( $field->name eq $fieldName ) {
            return $field;
        }
    }
    return 0;
}

sub fieldCount {
    my( $self ) = @_;

    return $self->{_fields} ? scalar @{$self->{_fields}} : 0;
}

sub updateHeader {
    my( $self ) = @_;

    my $dataPart = "";
    foreach my $field (@{$self->{_fields}}) {
        $dataPart .= FS.$field->name.$field->value;
    }
    $self->getHeader()->crc($self->getCrcHex($dataPart));
    $self->getHeader()->length(sprintf("%04X", length($dataPart)));
}

sub getCrcHex {
    my( $self, $data ) = @_;

    my $crc = Digest::CRC->new(width=>16, init => 0x0000, xorout => 0x0000,
                               refout => 0, poly => 0x11021, refin => 0, cont => 0);
    $crc->add($data);
    my $crcBin = $crc->digest;
    return sprintf("%04X",$crcBin);
}

sub isValid {
    my( $self ) = @_;

    return $self->{_isValid};
}

sub setValid {
    my ( $self, $valid ) = @_;
    $self->{_isValid} = $valid;
}

sub parse {
    my ( $self, $response ) = @_;

    my $hdr = $self->getHeader();

    my $first = substr $response, 0, 1;
    my $last = substr $response, -1;

    if (($first eq STX) && ($last eq ETX)) {
        $hdr->protocolType(substr $response, 1, 2);
        $hdr->protocolVersion(substr $response, 3, 2);
        $hdr->terminalID(substr $response, 5, 8);
        $hdr->dateTime(substr $response, 13, 12);
        $hdr->tags(substr $response, 25, 4);
        $hdr->length(substr $response, 29, 4);
        $hdr->crc(substr $response, 33, 4);
        $self->{_fields} = ();
        my $dataPart = substr $response, 37, -1;
        if ($hdr->crc eq $self->getCrcHex($dataPart)) {
            $self->parseFields($dataPart);
            $self->setValid(1);
        }
        else {
            $self->setValid(0);
        }
    }
#    print Dumper($self);

}

sub parseFields {
    my ( $self, $dataPart ) = @_;
    my $fs = FS;
    my @fields = split /$fs/, substr $dataPart, 1;

    foreach my $field (@fields) {
        my $fname = substr $field, 0, 1;
        my $fvalue = substr $field, 1;
        $self->addField($fname, $fvalue);
    }
    return 0;
}

sub decodeControlCharacters {
    my( $self, $msg ) = @_;

    $msg =~ s/[\x02]/\<STX\>/g;
    $msg =~ s/[\x03]/\<ETX\>/g;
    $msg =~ s/[\x1C]/\<FS\>/g;
    $msg =~ s/[\x1D]/\<GS\>/g;
    $msg =~ s/[\x0D]/\<CR\>/g;
    $msg =~ s/[\x0A]/\<LF\>/g;
    $msg =~ s/[\xFF]/\<0xFF\>/g;
    $msg =~ s/ /\<SPC\>/g;

    return $msg;
}

sub dumpString {
    my( $self ) = @_;
    return $self->decodeControlCharacters($self->getContent());
}

sub dumpObject {
    my( $self ) = @_;
    my $msg = $self->getHeader()->dumpObject();

    $msg .= "data:\n";
#    print Dumper($self);
#die();
    foreach my $field (@{$self->{_fields}}) {
        $msg .= "  ".$field->name.": '".$field->value."'\n";
    }
    return $msg;
}

1;