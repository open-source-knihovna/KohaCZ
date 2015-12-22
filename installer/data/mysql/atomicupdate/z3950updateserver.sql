ALTER IGNORE TABLE z3950servers
ADD zedu_omit_fields MEDIUMTEXT NULL,
ADD zedu_authoritative_id_field VARCHAR(8) NULL,
ADD zedu_msg_field VARCHAR(8) NULL,
ADD zedu_msg_oncreate MEDIUMTEXT NULL,
ADD zedu_msg_onupdate MEDIUMTEXT NULL,
MODIFY COLUMN servertype enum('zed', 'sru', 'zed_update') NOT NULL DEFAULT 'zed';

INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type` ) VALUES
('EnablePushingToAuthorityServer','0','','Enables pushing to authority server as an update or create action ','YesNo');
