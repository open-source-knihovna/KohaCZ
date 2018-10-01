$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {
    if( !column_exists( 'account_offsets', 'transaction_library' ) ) {
        $dbh->do( "ALTER TABLE account_offsets ADD COLUMN transaction_library varchar(10) default NULL AFTER created_on" );
        $dbh->do( "ALTER TABLE account_offsets ADD CONSTRAINT `account_offsets_ibfk_l` FOREIGN KEY (`transaction_library`) REFERENCES `branches` (`branchcode`) ON DELETE SET NULL ON UPDATE CASCADE" );
    }

    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug 21401 - Add transacting library to account_offsets)\n";
}
