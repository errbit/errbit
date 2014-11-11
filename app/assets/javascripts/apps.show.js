$(function() {

  $("[data-toggle='collapse']").click(function() {
    var collapableId = '#'+$(this).attr('aria-controls');
    $(collapableId).toggleClass('hidden')
  });
});
