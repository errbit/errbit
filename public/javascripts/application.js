// App JS

$(function(){
  activateTabbedPanels();

  $('#watcher_name').live("click", function() {
    $(this).closest('form').find('.show').removeClass('show');
    $('#app_watchers_attributes_0_user_id').addClass('show');
  });

  $('#watcher_email').live("click", function() {
    $(this).closest('form').find('.show').removeClass('show');
    $('#app_watchers_attributes_0_email').addClass('show');
  });

  $('a.copy_config').live("click", function() {
    $('select.choose_other_app').show().focus();
  });
  $('select.choose_other_app').live("change", function() {
    var loc = window.location;
    window.location.href = loc.protocol + "//" + loc.host + loc.pathname +
                           "?copy_attributes_from=" + $(this).val();
  });
});

function activateTabbedPanels() {
  $('.tab-bar a').each(function(){
    var tab = $(this);
    var panel = $('#'+tab.attr('rel'));
    panel.addClass('panel');
    panel.find('h3').hide();
  })

  $('.tab-bar a').click(function(){
    activateTab($(this));
    return(false);
  });
  activateTab($('.tab-bar a').first());
}

function activateTab(tab) {
  tab = $(tab);
  var panel = $('#'+tab.attr('rel'));

  tab.closest('.tab-bar').find('a.active').removeClass('active');
  tab.addClass('active');

  $('.panel').hide();
  panel.show();
}

