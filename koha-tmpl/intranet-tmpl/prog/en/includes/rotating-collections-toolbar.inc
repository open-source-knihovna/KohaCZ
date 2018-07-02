[% INCLUDE 'blocking_errors.inc' %]
<div id="toolbar" class="btn-toolbar">
    <div class="btn-group">
        <a class="btn btn-default btn-sm" href="/cgi-bin/koha/rotating_collections/editCollections.pl?action=new"><i class="fa fa-plus"></i> New collection</a>
    </div>
    [% IF ( collection.colId ) %]
        <div class="btn-group">
            <a class="btn btn-default btn-sm" href="/cgi-bin/koha/rotating_collections/transferCollection.pl?colId=[% collection.colId %]"><i class="fa fa-exchange"></i> Transfer</a>
        </div>
        <div class="btn-group">
            <a class="btn btn-default btn-sm" href="/cgi-bin/koha/tools/export.pl?rotating_collection=[% collection.colId %]&op=export"><i class="fa fa-arrow-right"></i> Export</a>
        </div>
        <div class="btn-group">
            <a class="btn btn-default btn-sm" href="/cgi-bin/koha/rotating_collections/editCollections.pl?action=edit&amp;colId=[% collection.colId %]"><i class="fa fa-pencil"></i> Edit</a>
        </div>
        <div class="btn-group">
            <a class="btn btn-default btn-sm confirmdelete" href="/cgi-bin/koha/rotating_collections/editCollections.pl?action=delete&amp;colId=[% collection.colId %]"><i class="fa fa-trash"></i> Delete</a>
        </div>
    [% END %]
</div>
