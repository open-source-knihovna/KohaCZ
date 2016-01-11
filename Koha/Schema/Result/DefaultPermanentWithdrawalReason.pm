use utf8;
package Koha::Schema::Result::DefaultPermanentWithdrawalReason;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::DefaultPermanentWithdrawalReason

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<default_permanent_withdrawal_reason>

=cut

__PACKAGE__->table("default_permanent_withdrawal_reason");

=head1 ACCESSORS

=head2 categorycode

  data_type: 'varchar'
  is_nullable: 1
  size: 10

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 250

=cut

__PACKAGE__->add_columns(
  "categorycode",
  { data_type => "varchar", is_nullable => 1, size => 10 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 250 },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2016-01-11 13:20:18
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:cr2G6mezX0TniK+6BcTuZw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
