$(function() {
  $("#watchers_toggle").click(function() {
    $("#watchers_div").slideToggle("slow");
  });
  $("#repository_toggle").click(function() {
    $("#repository_div").slideToggle("slow");
  });
  $("#deploys_toggle").click(function() {
    $("#deploys_div").slideToggle("slow");
  });
});
