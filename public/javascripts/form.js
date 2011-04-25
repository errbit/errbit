$(function(){
  activateNestedForms();

  if($('div.watcher.nested').length)
    activateWatcherTypeSelector();

  if($('div.issue_tracker.nested').length)
    activateIssueTrackerTypeSelector();
});

function activateNestedForms() {
  $('.nested-wrapper').each(function(){
    var wrapper = $(this);

    makeNestedItemsDestroyable(wrapper);

    var addLink = $('<a/>').text('add another').addClass('add-nested');
    addLink.click(appendNestedItem);
    wrapper.append(addLink);
  });
  $('.nested a.remove-nested').live('click',removeNestedItem);
}

function makeNestedItemsDestroyable(wrapper) {
  wrapper.find('.nested').each(function(){
    var nestedItem = $(this);
    var destroyLink = $('<a/>').text('remove').addClass('remove-nested');
    destroyLink.css('float','right');
    nestedItem.find('label').first().before(destroyLink);
  })
}

function appendNestedItem() {
  var addLink = $(this);
  var nestedItem = addLink.parent().find('.nested').first().clone().show();
  var timestamp = new Date();
  timestamp = timestamp.valueOf();

  nestedItem.find('input, select').each(function(){
    var input = $(this);
    input.attr('id', input.attr('id').replace(/([_\[])\d+([\]_])/,'$1'+timestamp+'$2'));
    input.attr('name', input.attr('name').replace(/([_\[])\d+([\]_])/,'$1'+timestamp+'$2'));
    if(input.attr('type') != 'radio')
      input.val('');
  });
  nestedItem.find('label').each(function(){
    var label = $(this);
    label.attr('for', label.attr('for').replace(/([_\[])\d+([\]_])/,'$1'+timestamp+'$2'));
  });
  addLink.before(nestedItem);
}

function removeNestedItem() {
  var destroyLink = $(this);
  var nestedItem = destroyLink.closest('.nested');
  var inputNameExample = nestedItem.find('input').first().attr('name');
  var idFieldName = inputNameExample.replace(/\[[^\]]*\]$/,'[id]');
  if($("input[name='"+idFieldName+"']").length) {
    var destroyFlagName = inputNameExample.replace(/\[[^\]]*\]$/,'[_destroy]')
    var destroyFlag = $('<input/>').attr('name',destroyFlagName).attr('type','hidden').val('true');
    $("input[name='"+idFieldName+"']").after(destroyFlag);
  }
  nestedItem.hide();
}

function activateWatcherTypeSelector() {
  $('div.watcher input[name*=watcher_type]').live('click', function(){
    var choosen = $(this).val();
    var wrapper = $(this).closest('.nested');
    wrapper.find('div.choosen').removeClass('choosen');
    wrapper.find('div.'+choosen).addClass('choosen');
  });
}

function activateIssueTrackerTypeSelector() {
  $('div.issue_tracker input[name*=issue_tracker_type]').live('click', function(){
    var chosen = $(this).val();
    var wrapper = $(this).closest('.nested');
    wrapper.find('div.chosen').removeClass('chosen');
    wrapper.find('div.'+chosen).addClass('chosen');
  });
}