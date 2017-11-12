$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {
    if( !column_exists( 'collections', 'createdBy' ) ) {
        $dbh->do( "ALTER TABLE collections ADD COLUMN createdBy int(11) default NULL AFTER colBranchcode" );
    }

    $dbh->do( "ALTER TABLE collections ADD CONSTRAINT `collections_ibfk_2` FOREIGN KEY (`createdBy`) REFERENCES `borrowers` (`borrowernumber`) ON DELETE SET NULL ON UPDATE CASCADE");

   if( !column_exists( 'collections', 'createdOn' ) ) {
        $dbh->do( "ALTER TABLE collections ADD COLUMN createdOn datetime default NULL AFTER createdBy" );
    }

    if( !column_exists( 'collections', 'lastTransferredOn' ) ) {
        $dbh->do( "ALTER TABLE collections ADD COLUMN lastTransferredOn datetime default NULL AFTER createdOn" );
    }

    # Always end with this (adjust the bug info)
    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug 19520 - Add additional information to rotating collections)\n";
}
