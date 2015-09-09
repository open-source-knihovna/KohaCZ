INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type` ) VALUES
('UsePermanentWithdrawal','0','','Use permanent withdrawal mode for withdrawing items. This generates an unique withdrawal number.','YesNo');
ALTER IGNORE TABLE items ADD withdrawn_permanent VARCHAR(32) AFTER withdrawn_on;
