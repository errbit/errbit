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

  autosize(document.querySelectorAll('textarea'));

  $(document.body).on("click", ".edit-comment", function(e) {
    e.preventDefault();
    var textarea = $(this).closest(".editable")
      .toggleClass("in-edit")
      .find("textarea")[0];
    if(textarea) {
      var e = document.createEvent('Event');
      e.initEvent('autosize:update', true, false);
      textarea.dispatchEvent(e);
    }
  });

  $(document.body).on("click", ".cancel-edit-comment", function(e) {
    e.preventDefault();
    e.stopImmediatePropagation();
    $(this).closest(".editable").removeClass("in-edit");
  });

});
