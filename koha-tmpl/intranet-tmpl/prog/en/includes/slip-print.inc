<script type="text/javascript">
[% IF ( Koha.Preference('IntranetSlipPrinterJS') ) %]
    [% Koha.Preference('IntranetSlipPrinterJS') %]
    $( window ).load( printThenClose() );
[% ELSE %]
    $( window ).load(function() {
        window.print();
        setTimeout('window.close()', 1);
    });
[% END %]
</script>
