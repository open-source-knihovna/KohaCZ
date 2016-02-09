#!/usr/bin/perl

# Copyright 2015 Josef Moravec
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
use CGI qw ( -utf8 );
use C4::Context;
use C4::Output;

=head1 DESCRIPTION
This plugin gets the stocknumber based on itype value in table items.
You should have 952i in your bibliographic frameworks set to appropriate value.
If a prefix is submited, we look for the highest stocknumber with this prefix, and return it incremented.

=cut

sub plugin_javascript {
    my ($dbh,$record,$tagslib,$field_number,$tabloop) = @_;
    my $res = qq{
    <script type='text/javascript'>
        function Focus$field_number() {
                var code = document.getElementById('$field_number');
                \$.ajax({
                    url: '/cgi-bin/koha/cataloguing/plugin_launcher.pl',
                    type: 'POST',
                    data: {
                        'plugin_name': 'stocknumberItype.pl',
                        'code'    : code.value,
                    },
                    success: function(data){
                        var field = document.getElementById('$field_number');
                        field.value = data;
                        return 1;
                    }
                });
        }
    </script>
    };

    return ($field_number,$res);
}

sub plugin {
    my ($input) = @_;
    my $code = $input->param('code');

    my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
        {   template_name   => "cataloguing/value_builder/ajax.tt",
            query           => $input,
            type            => "intranet",
            authnotrequired => 0,
            flagsrequired   => { editcatalogue => '*' },
            debug           => 1,
        }
    );

    my $dbh = C4::Context->dbh;

    # If a prefix is submited, we look for the highest stocknumber with this prefix, and return it incremented
    $code =~ s/ *$//g;
    if ( $code =~ m/^[A-Z]+$/ ) {
        my $sth = $dbh->prepare("SELECT MAX(stocknumber+0)+1 FROM items WHERE itype=?");
        $sth->execute( $code );

        if ( my $valeur = $sth->fetchrow ) {
            $template->param( return => $valeur );
        } else {
                $template->param( return => "There is no defined value for $code");
        }
        # The user entered a custom value, we don't touch it, this could be handled in js
    } else {
        $template->param( return => $code, );
    }

    output_html_with_http_headers $input, $cookie, $template->output;
}


