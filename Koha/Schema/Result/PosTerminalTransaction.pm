use utf8;
package Koha::Schema::Result::PosTerminalTransaction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Koha::Schema::Result::PosTerminalTransaction

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<pos_terminal_transactions>

=cut

__PACKAGE__->table("pos_terminal_transactions");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 accountlines_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 status

  data_type: 'varchar'
  default_value: 'new'
  is_nullable: 0
  size: 32

=head2 response_code

  data_type: 'varchar'
  is_nullable: 1
  size: 5

=head2 message_log

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "accountlines_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "status",
  {
    data_type => "varchar",
    default_value => "new",
    is_nullable => 0,
    size => 32,
  },
  "response_code",
  { data_type => "varchar", is_nullable => 1, size => 5 },
  "message_log",
  { data_type => "text", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 accountline

Type: belongs_to

Related object: L<Koha::Schema::Result::Accountline>

=cut

__PACKAGE__->belongs_to(
  "accountline",
  "Koha::Schema::Result::Accountline",
  { accountlines_id => "accountlines_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07042 @ 2017-03-22 17:13:47
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9kf34Odpc7Yd46+Lu2pyJg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
