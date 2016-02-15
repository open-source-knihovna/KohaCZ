ALTER IGNORE TABLE borrowers ADD COLUMN `checkprevissue` varchar(7) NOT NULL default 'inherit' AFTER privacy;
ALTER IGNORE TABLE deletedborrowers ADD COLUMN `checkprevissue` varchar(7) NOT NULL default 'inherit' AFTER privacy;

ALTER IGNORE TABLE categories ADD COLUMN `checkprevissue` varchar(7) NOT NULL default 'inherit';

INSERT IGNORE INTO systempreferences ( `variable`, `value`, `options`, `explanation`, `type` ) VALUES
('CheckPrevIssue','1','','By default, for every item issued, should we warn if the patron has borrowed that item in the past?','YesNo');
