ALTER IGNORE TABLE z3950servers
ADD update_omit_fields MEDIUMTEXT NOT NULL,
MODIFY COLUMN servertype enum('zed', 'sru', 'zed_update') NOT NULL DEFAULT 'zed';

INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type` ) VALUES
('EnablePushingToAuthorityServer','0','','Enables pushing to authority server as an update or create action ','YesNo');
