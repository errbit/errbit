// App JS

$(function() {

  var currentTab = $('ul.nav-tabs li.active').find('a').attr('rel');

  function init() {
    activateSelectableRows();

    toggleProblemsCheckboxes();

    // On page apps/:app_id/edit
    $('a.copy_config').on("click", function() {
      $('select.choose_other_app').removeClass("hidden").focus();
    });

    $('select.choose_other_app').on("change", function() {
      var loc = window.location;
      window.location.href = loc.protocol + "//" + loc.host + loc.pathname +
                             "?copy_attributes_from=" + $(this).val();
    });


    // On page users/new
    // On page users/:user_id/edit
    // mark the password fields as not required if a github username is specified
    bindRequiredPasswordMarks('#user_github_login');



    $('input[type=submit][data-action]').on('click', function() {
      $(this).closest('form').attr('action', $(this).attr('data-action'));
    });


    // collapse the backtrace each time we view that tab
    $('ul.nav-tabs').on('click', 'a[rel=backtrace]', function () {
      hide_external_backtrace();
    })


    $('.notice-pagination').each(function() {
      $.pjax.defaults = {timeout: 2000};

      $('#content').pjax('.notice-pagination a').on('pjax:start', function() {
        // show the spinner and remember what tab is current so we can reselect it
        $('.notice-pagination-loader').removeClass("hidden");
        currentTab = $('ul.nav-tabs li.active a').attr('rel');
      }).on('pjax:end', function() {
        // reselect the tab that was current before the content was reloaded
        $('ul.nav-tabs li').removeClass('active');
        $('div.tab-content div').removeClass('active');
        $('ul.nav-tabs li > a[rel=' + currentTab + ']').parent().addClass("active");
        $('div#' + currentTab).addClass("active");
      });
    });

  }


  window.toggleProblemsCheckboxes = function() {
    var checkboxToggler = $('#toggle_problems_checkboxes');

    checkboxToggler.on("click", function() {
      $('input[name^="problems"]').each(function() {
        this.checked = checkboxToggler.get(0).checked;
      });
    });
  }

  function activateSelectableRows() {
    $('div.problems-list').on('click', 'div.content.row', function(event) {
      if(!_.include(['A', 'INPUT', 'BUTTON', 'TEXTAREA'], event.target.nodeName)) {
        var checkbox = $(this).find('input[name="problems[]"]');
        checkbox.prop('checked', !checkbox.prop('checked'));
      }
    });
  }


  function bindRequiredPasswordMarks(username_el) {
    $(username_el).keyup(function(event) {
      toggleRequiredPasswordMarks(this);
    });

    // set initial state before user interaction
    toggleRequiredPasswordMarks(username_el);
  }

  function toggleRequiredPasswordMarks(input) {
    if ($(input).val() == "") {
      $('#user_password').parent().addClass('required');
      $('#user_password_confirmation').parent().addClass('required');
    } else {
      $('#user_password').parent().removeClass('required');
      $('#user_password_confirmation').parent().removeClass('required');
    }
  }


  function hide_external_backtrace() {
    $('.toggle_external_backtrace').hide();
    $('.backtrace_separator').show();
  }
  function show_external_backtrace() {
    $('.toggle_external_backtrace').show();
    $('.backtrace_separator').hide();
  }
  // Show external backtrace lines when clicking separator
  $('.backtrace_separator').on('click', show_external_backtrace);
  // Hide external backtrace on page load
  hide_external_backtrace();


  $('.head a.show_tail').click(function(e) {
    $(this).hide().closest('.head_and_tail').find('.tail').show();
    e.preventDefault();
  });

  init();
});
