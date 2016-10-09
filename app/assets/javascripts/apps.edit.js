/**
 * Created by chteijon on 09/10/2016.
 */


$(function() {
    $('#other_use_site_fingerprinter').change(function() {
        if (this.checked) {
            $('.custom_notice_fingerprinter').hide();
        } else {
            $('.custom_notice_fingerprinter').show();
        }
    });
});