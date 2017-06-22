package Koha::PosTerminal::Client;

# This file is part of Koha.
#
# Copyright 2014 BibLibre
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

use IO::Socket::INET;
use IO::Socket::Timeout;
use Koha::PosTerminal::Message;
use Errno qw(ETIMEDOUT EWOULDBLOCK);

use constant {
    ERR_CONNECTION_FAILED => -1,
    ERR_NO_RESPONSE => -2
};

# auto-flush on socket
$| = 1;

sub new {
    my $class  = shift;
    my $self = {
        _ip => shift,
        _port => shift,
        _socket => 0,
    };

    bless $self, $class;
    return $self;
}

sub connect {
    my ( $self ) = @_;

    $self->{_socket} = new IO::Socket::INET (
        PeerHost => $self->{_ip},
        PeerPort => $self->{_port},
        Proto => 'tcp',
        Timeout => 5
    );

    if ($self->{_socket}) {
        IO::Socket::Timeout->enable_timeouts_on($self->{_socket});
        $self->{_socket}->read_timeout(60);
        $self->{_socket}->write_timeout(60);
    }

    return !!$self->{_socket};
}

sub disconnect {
    my ( $self ) = @_;

    $self->{_socket}->close();
}

sub send {
    my ( $self, $message ) = @_;

    # data to send to a server
    my $req = $message->getContent();
    my $size = $self->{_socket}->send($req);
}

sub receive {
    my ( $self ) = @_;

    my $socket = $self->{_socket};

#    my $response = <$socket>;
    my $response;
    $self->{_socket}->recv($response, 1024);
    if (!$response) {
        if (( 0+$! == ETIMEDOUT) || (0+$! == EWOULDBLOCK )) {
            return ERR_CONNECTION_FAILED;
        }
        else {
            return 0+$!; #ERR_NO_RESPONSE;
        }
    }

    my $msg = new Koha::PosTerminal::Message(Koha::PosTerminal::Message::DIR_RECEIVED);
    $msg->parse($response);

    return $msg;
}

1;