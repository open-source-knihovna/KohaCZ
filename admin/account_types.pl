#! /usr/bin/perl

# Copyright 2016 Koha Development Team
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
use CGI qw ( -utf8 );
use C4::Context;
use C4::Auth;
use C4::Output;

use Koha::Account::CreditTypes;
use Koha::Account::DebitTypes;

my $input     = new CGI;
my $type_code = $input->param('type_code');
my $op        = $input->param('op') || 'list';
my $type      = $input->param('type');
my @messages;

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {   template_name   => "admin/account_types.tt",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => { parameters => 'parameters_remaining_permissions' },
        debug           => 1,
    }
);

#my $dbh = C4::Context->dbh;
if ( $op eq 'add_form' ) {
    my $account_type;
    if ($type_code) {
        if ($type eq "debit") {
            $account_type = Koha::Account::DebitTypes->find($type_code);
        } else {
            $account_type = Koha::Account::CreditTypes->find($type_code);
        }
    }
    $template->param( account_type => $account_type );
    $template->param( type => $type );
} elsif ( $op eq 'add_validate' ) {
    my $description           = $input->param('description');
    my $can_be_added_manually = $input->param('can_be_added_manually') || 0;
    my $default_amount;
    if ($type eq "debit") {
        $default_amount = $input->param('default_amount') || undef;
    }

    my $account_type;
    if($type eq "debit") {
        $account_type = Koha::Account::DebitTypes->find($type_code);
        if (not defined $account_type) {
            $account_type = Koha::Account::DebitType->new( { type_code => $type_code } );
        }
    } else {
        $account_type = Koha::Account::CreditTypes->find($type_code);
        if (not defined $account_type) {
             $account_type = Koha::Account::CreditType->new( { type_code => $type_code } );
        }
    }
    $account_type->description($description);
    $account_type->can_be_added_manually($can_be_added_manually);
    if($type eq "debit") {
        $account_type->default_amount($default_amount);
    }
    eval { $account_type->store; };
    if ($@) {
        push @messages, { type => 'error', code => 'error_on_saving' };
    } else {
        push @messages, { type => 'message', code => 'success_on_saving' };
    }
    $op          = 'list';
} elsif ( $op eq 'delete_confirm' ) {
    my $account_type;
    if($type eq "debit") {
        $account_type = Koha::Account::DebitTypes->find($type_code);
    } else {
        $account_type = Koha::Account::CreditTypes->find($type_code);
    }
    $template->param( account_type => $account_type );
    $template->param( type => $type );
} elsif ( $op eq 'delete_confirmed' ) {
    my $account_type;
    if($type eq "debit") {
        $account_type = Koha::Account::DebitTypes->find($type_code);
    } else {
        $account_type = Koha::Account::CreditTypes->find($type_code);
    }
    my $deleted = eval { $account_type->delete; };

    if ( $@ or not $deleted ) {
        push @messages, { type => 'error', code => 'error_on_delete' };
    } else {
        push @messages, { type => 'message', code => 'success_on_delete' };
    }
    $op = 'list';
}

if ( $op eq 'list' ) {
    my $credit_types = Koha::Account::CreditTypes->search();
    my $debit_types = Koha::Account::DebitTypes->search();
    $template->param(
        debit_types  => $debit_types,
        credit_types => $credit_types,
    );
}

$template->param(
    type_code   => $type_code,
    messages    => \@messages,
    op          => $op,
);

output_html_with_http_headers $input, $cookie, $template->output;
