INSERT INTO account_credit_types (type_code, description, can_be_deleted, can_be_added_manually) VALUES
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
    ('W',   'Write Off',    0, 0);
