INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type` ) VALUES
('UsePermanentWithdrawal','0','','Use permanent withdrawal mode for withdrawing items. This generates an unique withdrawal number.','YesNo');
ALTER IGNORE TABLE items ADD withdrawn_permanent VARCHAR(32) AFTER withdrawn_on;
ALTER IGNORE TABLE items ADD withdrawn_categorycode VARCHAR(10) AFTER withdrawn_on;
CREATE TABLE IF NOT EXISTS default_permanent_withdrawal_reason(
        categorycode VARCHAR(10) DEFAULT NULL,
        description VARCHAR(250) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT IGNORE INTO default_permanent_withdrawal_reason
	(categorycode, description)
VALUES
	('focus', 'does not match the focus of the library'),
	('multi', 'multiplicates document'),
	('damaged', 'worn or damaged'),
	('lost', 'lost by reader');
