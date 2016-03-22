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

  $(".mdown pre > code").each(function() {
    var $el = $(this);
    var language = $el.attr("class");
    var grammar = Prism.languages[language];
    if(grammar) {
      $el.html(Prism.highlight($el.text(), grammar));
    } else {
      if(console && console.log) {
        console.log("[app.show.js] Grammar for '" + language + "' not installed");
      }
    }
  });
});
