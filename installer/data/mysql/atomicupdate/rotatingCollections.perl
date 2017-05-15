$DBversion = 'XXX';  # will be replaced by RM
if( CheckVersion( $DBversion ) ) {
    $dbh->do( "ALTER TABLE collections_tracking ADD CONSTRAINT collections_tracking_ibfk_1 FOREIGN KEY (colId) REFERENCES collections (colId) ON DELETE CASCADE ON UPDATE CASCADE" );    $dbh->do( "ALTER TABLE collections_tracking ADD CONSTRAINT collections_tracking_ibfk_2 FOREIGN KEY (itemnumber) REFERENCES items (itemnumber) ON DELETE CASCADE ON UPDATE CASCADE" );

    SetVersion( $DBversion );
    print "Upgrade to $DBversion done (Bug XXXXX - Rotating collections objects)\n";
}
