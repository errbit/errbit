// App JS

$(function() {

  var currentTab = "summary";

  function init() {

    activateTabbedPanels();

    activateSelectableRows();

    toggleProblemsCheckboxes();

    bindRequiredPasswordMarks();

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

    $('input[type=submit][data-action]').click(function() {
      $(this).closest('form').attr('action', $(this).attr('data-action'));
    });

    $('.notice-pagination').each(function() {
      $('.notice-pagination a').pjax('#content', { timeout: 2000});
      $('#content').bind('pjax:start',  function() {
  $('.notice-pagination-loader').css("visibility", "visible");
        currentTab = $('.tab-bar ul li a.button.active').attr('rel');
      });

      $('#content').bind('pjax:end',  function() {
        activateTabbedPanels();
      });
    });
  }

  function activateTabbedPanels() {
    $('.tab-bar a').each(function(){
      var tab = $(this);
      var panel = $('#'+tab.attr('rel'));
      panel.addClass('panel');
      panel.find('h3').hide();
    });

    $('.tab-bar a').click(function(){
      activateTab($(this));
      return(false);
    });
    activateTab($('.tab-bar ul li a.button[rel=' + currentTab + ']'));
  }

  function activateTab(tab) {
    tab = $(tab);
    var panel = $('#'+tab.attr('rel'));

    tab.closest('.tab-bar').find('a.active').removeClass('active');
    tab.addClass('active');

    // If clicking into 'backtrace' tab, hide external backtrace
    if (tab.attr('rel') == "backtrace") { hide_external_backtrace(); }

    $('.panel').hide();
    panel.show();
  }

  function toggleProblemsCheckboxes() {
    var checkboxToggler = $('#toggle_problems_checkboxes');

    checkboxToggler.live("click", function() {
      $('input[name^="problems"]').each(function() {
        this.checked = checkboxToggler.get(0).checked;
      });
    });
  }

  function activateSelectableRows() {
    $('.selectable tr').click(function(event) {
      if(!_.include(['A', 'INPUT', 'BUTTON', 'TEXTAREA'], event.target.nodeName)) {
        var checkbox = $(this).find('input[name="problems[]"]');
        checkbox.attr('checked', !checkbox.is(':checked'));
      }
    });
  }

  function bindRequiredPasswordMarks() {
    $('#user_github_login').keyup(function(event) {
      toggleRequiredPasswordMarks(this)
    });
  }

  function toggleRequiredPasswordMarks(input) {
      if($(input).val() == "") {
        $('#user_password').parent().attr('class', 'required')
        $('#user_password_confirmation').parent().attr('class', 'required')
      } else {
        $('#user_password').parent().attr('class', '')
        $('#user_password_confirmation').parent().attr('class', '')
      }
  }

  toggleRequiredPasswordMarks();

  function hide_external_backtrace() {
    $('tr.toggle_external_backtrace').hide();
    $('td.backtrace_separator').show();
  }
  function show_external_backtrace() {
    $('tr.toggle_external_backtrace').show();
    $('td.backtrace_separator').hide();
  }
  // Show external backtrace lines when clicking separator
  $('td.backtrace_separator span').live('click', show_external_backtrace);
  // Hide external backtrace on page load
  hide_external_backtrace();

  init();
});
