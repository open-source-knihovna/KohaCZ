$DBversion = 'XXX';  # will be replaced by the RM
if( CheckVersion( $DBversion ) ) {
    if( !column_exists( 'issuingrules', 'maxissuelength' ) ) {
        $dbh->do( "ALTER TABLE issuingrules ADD COLUMN maxissuelength int(4) default NULL AFTER issuelength" );
    }

    # Always end with this (adjust the bug info)
    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Max issue length)\n";
}
