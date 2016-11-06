/**
 * Created by chteijon on 09/10/2016.
 */


$(function() {
    $('#other_use_site_fingerprinter').change(function() {
        $('.custom_notice_fingerprinter').toggle(!this.checked);
    });
});