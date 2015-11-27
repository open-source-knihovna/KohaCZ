ALTER IGNORE TABLE z3950servers
MODIFY COLUMN servertype enum('zed', 'sru', 'zed_update') NOT NULL DEFAULT 'zed',
ADD update_omit_fields MEDIUMTEXT NOT NULL;
