use utf8;
package Koha::Schema::Result::AccountCreditType;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::AccountCreditType

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<account_credit_types>

=cut

__PACKAGE__->table("account_credit_types");

=head1 ACCESSORS

=head2 type_code

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 description

  data_type: 'varchar'
  is_nullable: 1
  size: 200

=head2 can_be_deleted

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=head2 can_be_added_manually

  data_type: 'tinyint'
  default_value: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "type_code",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "description",
  { data_type => "varchar", is_nullable => 1, size => 200 },
  "can_be_deleted",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
  "can_be_added_manually",
  { data_type => "tinyint", default_value => 1, is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</type_code>

=back

=cut

__PACKAGE__->set_primary_key("type_code");


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2018-10-01 06:33:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VBRjqBVRMk217Ba7f4ewyg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
