// App JS

$(function() {

  var currentTab = "summary";

  function init() {

    activateTabbedPanels();

    activateSelectableRows();

    toggleProblemsCheckboxes();

    bindRequiredPasswordMarks();

    // On page apps/:app_id/edit
    $('a.copy_config').on("click", function() {
      $('select.choose_other_app').removeClass('hidden').focus();
    });

    $('select.choose_other_app').on("change", function() {
      var loc = window.location;
      window.location.href = loc.protocol + "//" + loc.host + loc.pathname +
                             "?copy_attributes_from=" + $(this).val();
    });

    bindProblemButtonsActions();

    $('.notice-pagination').each(function() {
      $.pjax.defaults = {timeout: 2000};

      $('#content').pjax('.notice-pagination a').on('pjax:start', function() {
        $('.notice-pagination-loader').addClass('visible');
        currentTab = $('.tab-bar ul li a.button.active').attr('rel');
      }).on('pjax:end', function() {
        activateTabbedPanels();
        loadSparklines();
      });
    });
  }

  function activateTabbedPanels() {
    $('.tab-bar a').each(function(){
      var tab = $(this);
      var panel = $('#'+tab.attr('rel'));
      panel.addClass('panel');
      panel.find('h3').addClass('hidden');
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

    $('.panel').addClass('hidden');
    panel.removeClass('hidden');
  }

  window.toggleProblemsCheckboxes = function() {
    var checkboxToggler = $('#toggle_problems_checkboxes');

    checkboxToggler.on("click", function() {
      $('input[name^="problems"]').each(function() {
        this.checked = checkboxToggler.get(0).checked;
      });
    });
  }

  window.bindProblemButtonsActions = function() {
      $('input[type=submit][data-action]').on('click', function() {
          $(this).closest('form').attr('action', $(this).attr('data-action'));
      });
  };

    function activateSelectableRows() {
    $('.selectable tr').click(function(event) {
      if(!_.include(['A', 'INPUT', 'BUTTON', 'TEXTAREA'], event.target.nodeName)) {
        var checkbox = $(this).find('input[name="problems[]"]').get(0);
        checkbox.checked = !checkbox.checked;
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
    $('tr.toggle_external_backtrace').addClass('hidden_external_backtrace');
    $('td.backtrace_separator').removeClass('hidden');
  }
  function show_external_backtrace() {
    $('tr.toggle_external_backtrace').removeClass('hidden_external_backtrace');
    $('td.backtrace_separator').addClass('hidden');
  }
  // Show external backtrace lines when clicking separator
  $(document).on('click', 'td.backtrace_separator span', show_external_backtrace);
  // Hide external backtrace on page load
  hide_external_backtrace();

  $('.head a.show_tail').click(function(e) {
    $(this).addClass('hidden').closest('.head_and_tail').find('.tail').removeClass('hidden');
    e.preventDefault();
  });

  function loadSparklines() {
    $('#sparkline-placeholder[data-sparkline-url]').each(function() {
      var placeholder = $(this);
      $.ajax({url: placeholder.data('sparkline-url')}).then(function(response) {
        placeholder.replaceWith(response);
      });
    });
  }

  $('a#forgot_password').click(function(e) {
    // Set email field on password reset page to email that user entered on this page.
    e.preventDefault();
    window.location.href = $(this).attr('href') + '?email=' + encodeURIComponent($('#user_email').val());
  });

  loadSparklines();

  init();
});
