$DBversion = 'XXX';
if( CheckVersion( $DBversion ) ) {
    # Create pos_terminal_transactions table:
    $dbh->do( "CREATE TABLE IF NOT EXISTS `pos_terminal_transactions` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `accountlines_id` int(11) NOT NULL,
            `status` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT 'new',
            `response_code` varchar(5) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
            `message_log` text CHARACTER SET utf8 COLLATE utf8_unicode_ci,
            PRIMARY KEY (`id`),
            KEY `accountlines_id` (`accountlines_id`),
            CONSTRAINT `pos_terminal_transactions_ibfk1` FOREIGN KEY (`accountlines_id`) REFERENCES `accountlines` (`accountlines_id`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" );

    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug 17705 - Payments with cards through payment terminal)\n";
}
