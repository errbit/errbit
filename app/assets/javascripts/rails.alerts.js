/*
 * Replaces default rails.confirm implementation with $.alerts.confirm.
 */

(function($) {
  $.rails.confirm = function(msg) {
    var answer = $.Deferred();
    $.alerts.confirm(msg, 'Confirmation', function(r) {
      $.rails.resolveOrReject(answer, r);
    });
    return answer.promise();
  };
})(jQuery);

