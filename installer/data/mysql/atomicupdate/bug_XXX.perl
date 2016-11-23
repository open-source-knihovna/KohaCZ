$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {

$dbh->do( "
    CREATE TABLE IF NOT EXISTS account_debit_types (
        type_code varchar(5) NOT NULL,
        default_amount decimal(28,6) NULL,
        description varchar(200) NULL,
        can_be_deleted tinyint NOT NULL DEFAULT '1',
        can_be_added_manually tinyint(4) NOT NULL DEFAULT '1',
        PRIMARY KEY (type_code)
    ) COMMENT='' ENGINE='InnoDB' COLLATE 'utf8_unicode_ci'
" );

$dbh->do( "
    CREATE TABLE IF NOT EXISTS account_credit_types (
        type_code varchar(5) NOT NULL,
        description varchar(200) NULL,
        can_be_deleted tinyint NOT NULL DEFAULT '1',
        can_be_added_manually tinyint(4) NOT NULL DEFAULT '1',
        PRIMARY KEY (type_code)
    ) COMMENT='' ENGINE='InnoDB' COLLATE 'utf8_unicode_ci'
" );

$dbh->do( "
    INSERT IGNORE INTO account_debit_types (type_code, default_amount, description, can_be_deleted, can_be_added_manually) VALUES
    ('A',   NULL,   'Account management fee',   0,  1),
    ('F',   NULL,   'Overdue fine', 0,  1),
    ('FU',  NULL,   'Accruing overdue fine',    0,  0),
    ('L',   NULL,   'Lost item',    0,  1),
    ('LR',  NULL,   'Lost and returned',    0,  0),
    ('M',   NULL,   'Sundry',   0,  1),
    ('N',   NULL,   'New card', 0,  1),
    ('O',   NULL,   'Overdue fine', 0,  0),
    ('Rent',    NULL,   'Rental fee',   0,  1),
    ('Rep', NULL,   'Replacement',  0,  0),
    ('Res', NULL,   'Reserve charge',   0,  1)
" );

$dbh->do( "
    INSERT IGNORE INTO account_debit_types (type_code, default_amount, description, can_be_deleted, can_be_added_manually)
    SELECT SUBSTR(authorised_value,1,5), lib, authorised_value, 1, 1
    FROM authorised_values WHERE category='MANUAL_INV'
" );

$dbh->do( "
    INSERT IGNORE INTO account_credit_types (type_code, description, can_be_deleted, can_be_added_manually) VALUES
    ('C',   'Credit',   0, 1),
    ('CC',  'Credit card',  0, 0),
    ('CR',  'Refunded found lost item', 0, 0),
    ('FFOR',    'Forgiven overdue fine',    0, 0),
    ('FOR', 'Forgiven', 0, 1),
    ('OL',  'Other online payment service', 0, 0),
    ('Pay', 'Cash', 0, 0),
    ('Pay00',   'Cash via SIP2',    0, 0),
    ('Pay01',   'VISA via SIP2',    0, 0),
    ('Pay02',   'Credit card via SIP2', 0, 0),
    ('PayPa',   'PayPal',   0, 0),
    ('W',   'Write Off',    0, 0)
" );

$dbh->do( "
    ALTER IGNORE TABLE `accountlines`  ADD `paymenttype` varchar(5) COLLATE 'utf8_unicode_ci' NULL AFTER `accounttype`
" );

    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug XXXXX - description)\n";
}
