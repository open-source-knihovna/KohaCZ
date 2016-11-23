INSERT INTO account_debit_types (type_code, default_amount, description, can_be_deleted, can_be_added_manually) VALUES
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
    ('Res', NULL,   'Reserve charge',   0,  1),
    ('Copie', 0.5,  'Copier fees', 1, 1);
