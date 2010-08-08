// App JS

$(function(){
  activateTabbedPanels();
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