$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {
    if( !column_exists( 'issuingrules', 'renew_reserved' ) ) {
        $dbh->do( "ALTER TABLE issuingrules ADD COLUMN renew_reserved BOOLEAN default FALSE AFTER article_requests" );
    }

    if( !column_exists( 'issuingrules', 'reserved_renew_count' ) ) {
        $dbh->do( "ALTER TABLE issuingrules ADD COLUMN reserved_renew_count int(4) default NULL AFTER renew_reserved" );
    }

    if( !column_exists( 'issuingrules', 'reserved_renew_period' ) ) {
        $dbh->do( "ALTER TABLE issuingrules ADD COLUMN reserved_renew_period int(4) default NULL AFTER reserved_renew_count" );
    }

    # Always end with this (adjust the bug info)
    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Ability to renew reserved items)\n";
}
