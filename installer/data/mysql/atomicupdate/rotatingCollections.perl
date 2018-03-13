$DBversion = 'XXX';  # will be replaced by RM
if( CheckVersion( $DBversion ) ) {
    # Remove lines referencing non existing collections
    $dbh->do( "DELETE FROM collections_tracking WHERE colId NOT IN (SELECT colId FROM collections)" );
    # Remove lines referencing non existing items
    $dbh->do( "DELETE FROM collections_tracking WHERE itemnumber NOT IN (SELECT itemnumber FROM items)" );
    $dbh->do( "ALTER TABLE collections_tracking ADD CONSTRAINT collections_tracking_ibfk_1 FOREIGN KEY (colId) REFERENCES collections (colId) ON DELETE CASCADE ON UPDATE CASCADE" );
    $dbh->do( "ALTER TABLE collections_tracking ADD CONSTRAINT collections_tracking_ibfk_2 FOREIGN KEY (itemnumber) REFERENCES items (itemnumber) ON DELETE CASCADE ON UPDATE CASCADE" );

    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug 18606 - Rotating collections objects)\n";
}
