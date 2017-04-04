package Koha::REST::V1::MessagingPreferences;

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

use Mojo::Base 'Mojolicious::Controller';

use JSON qw/to_json/;

use Koha::Patrons;

use C4::Context;
use C4::Auth qw( haspermission );

sub set {

    #
    # WORK IN PROGRESS
    #
   
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');

    if ( ! C4::Context->preference('EnhancedMessagingPreferences') ) {
            return $c->$cb({error => "Enhanced messaging preferences are not enabled"}, 403);
    }

    if ( ! 
        ( C4::Context->preference('EnhancedMessagingPreferencesOPAC') ||
            C4::Auth::haspermission($user->userid, 'borrowers') )
    ) {

            return $c->$cb({error => "Patrons does not have access to enhanced messaging preferences"}, 403);
    }

    my $body = $c->req->json; 
 
    my $borrowernumber = $body->{borrowernumber}; 
    my $biblionumber = $body->{biblionumber}; 
    my $itemnumber = $body->{itemnumber}; 
    my $branchcode = $body->{branchcode}; 
    my $expirationdate = $body->{expirationdate}; 
    my $borrower = Koha::Patrons->find($borrowernumber);

    my $messaging_options = C4::Members::Messaging::GetMessagingOptions();

    my $prefs_set = 0;
    OPTION: foreach my $option ( @$messaging_options ) {
        my $updater = { borrowernumber => $user->borrowernumber, 
                        message_attribute_id    => $option->{'message_attribute_id'} };
        
        # find the desired transports
        @{$updater->{'message_transport_types'}} = $query->multi_param( $option->{'message_attribute_id'} );
        next OPTION unless $updater->{'message_transport_types'};

        if ( $option->{'has_digest'} ) {
            if ( List::Util::first { $_ == $option->{'message_attribute_id'} } $query->multi_param( 'digest' ) ) {
                $updater->{'wants_digest'} = 1;
            }
        }

        if ( $option->{'takes_days'} ) {

            # Here inserts number of days in advance ..
            if ( defined $query->param( $option->{'message_attribute_id'} . '-DAYS' ) ) {
                $updater->{'days_in_advance'} = $query->param( $option->{'message_attribute_id'} . '-DAYS' );
            }
        }

        C4::Members::Messaging::SetMessagingPreference( $updater );

	    if ($query->param( $option->{'message_attribute_id'})){
	        $prefs_set = 1;
	    }
    }

    return $c->$cb($patrons, 200);
}

sub get {
    my ($c, $args, $cb) = @_;

    my $user = $c->stash('koha.user');

    if ( ! C4::Context->preference('EnhancedMessagingPreferences') ) {
            return $c->$cb({error => "Enhanced messaging preferences are not enabled"}, 403);
    }

    if ( ! 
        ( C4::Context->preference('EnhancedMessagingPreferencesOPAC') ||
            C4::Auth::haspermission($user->userid, 'borrowers') )
    ) {
            return $c->$cb({error => "Patrons does not have access to enhanced messaging preferences"}, 403);
    }

    my $patron = Koha::Patrons->find($args->{borrowernumber});
    unless ($patron) {
        return $c->$cb({error => "Patron not found"}, 404);
    }

    #return $c->$cb({error => to_json($patron->messaging_preferences)}, 403);

    return $c->$cb($patron->messaging_preferences, 200);
}

1
