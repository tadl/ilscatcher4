var ready = function(){
  /* item details links fire onclick when clicked but follow link when opened in new tab */
  $(document).on('click', '.item_details_link', function(e) {
    if (e.which == 1) {
      e.preventDefault();
    }
  });

  // load salvattore
  $.getScript('/assets/salvattore.min.js');

  // left and right arrows to move between items
  var take_a_break = false
  $(document).keydown(function(e){
    if (e.which == 37 && $('.previous_link').is(':visible')) {
        if(take_a_break == false) {
          take_a_break = true
          setTimeout(function() { take_a_break = false }, 500);
          $('.previous_link').click()
        }
    }
    if (e.which == 39 && $('.next_link').is(':visible')) {
      if(take_a_break == false) {
        take_a_break = true
        setTimeout(function() { take_a_break = false }, 500);
        $('.next_link').click()
      }
    }
  });

  var windowWidth = $(window).width();
  if (windowWidth <= 768) {
    $('.toggles').collapse('hide');
  }


}

$(document).ready(ready);
$(window).resize(function() {
  var windowWidth = $(window).width();
  if (windowWidth <= 768) {
    $('.toggles').collapse('hide');
  } else {
    $('.toggles').collapse('show');
  }
});


/* open fancybox with item details */
function item_details(id, from, order, location_id) {
  var params = {};
  if (from) {
    params['from'] = from
  }
  if (order) {
    params['order'] = order
  }
  if (location_id) {
    params['location'] = location_id
  }
  params['id'] = id;
  $.post("/details.js", params);
}

function missing_cover(id, type) {
  var icon_array = [['a','book','text'],
                        ['c','music','notated music'],
                        ['d','music','notated music'],
                        ['e','globe-americas','cartographic'],
                        ['f','globe-americas','cartographic'],
                        ['g','film','moving image'],
                        ['i','compact-disc','sound recording-nonmusical'],
                        ['j','compact-disc','sound recording-musical'],
                        ['k','image','still image'],
                        ['m','save','software, multimedia'],
                        ['o','briefcase','kit'],
                        ['p','briefcase','mixed-material'],
                        ['r','cube','three dimensional object'],
                        ['t','book','text'],
                    ]
  icon = 'book';
  $.each(icon_array, function(index, value) {
    if (value[2] == type) {
      icon = value[1];
    }
  });
  var target_div_list = '#item_cover_' + id;
  var target_div_grid = '#grid_item_cover_' + id;
  var target_div_details = target_div_list + '_details';
  var icon_base = '<i class="fas fa-'+ icon;
  //Use this size of icon for gird and details
  var icon_html_grid_details = icon_base + ' fa-10x"></i>';
  //Use a small and large icon for list display and only show right sized based on breakpoint
  var icon_html_large_list = icon_base + ' fa-10x d-block d-sm-none"></i>';
  var icon_html_small_list = icon_base + ' fa-7x d-none d-sm-block"></i>';
  var icon_html_both_list = icon_html_large_list + icon_html_small_list
  //Put the right html into the right div
  $(target_div_list).html(icon_html_both_list);
  $(target_div_details).html(icon_html_grid_details);
  $(target_div_grid).html(icon_html_grid_details);
}

function check_blank_cover(image) {
  if (image.naturalWidth == 1) {
    $(image).trigger('error');
  }
}

function need_login(element, id) {
  $('#hold-record').val(id);
  $('#login-button').text('Sign in and Place Hold');
  $(element).addClass('disabled')
  console.log('Need to log in to place hold');
  $('#login-form').dropdown('toggle');
}

function do_login() {

  var username = $('#username').val();
  var password = $('#password').val();
  var placing_hold = false;

  $('.btn-login-hold').removeClass('disabled');

  if (username != "" && password != "") {
    var hold_record = $('#hold-record').val();

    if (hold_record != "") {
      placing_hold = true;
      $('#hold-record').val('');
    }

    $.post("login.js", {username: username, password: password, hold: hold_record});

    $('#login-message').text('');
  } else {
    $('#login-message').text('Please specify username and password');
  }


  return false;


}

function do_logout() {
  $.post("logout.js");
}

function place_hold(id, force) {
  var force_hold = (typeof force !== 'undefined') ? 'true' : 'false';
  var token = Cookies.get('login')
  if (token == null) {
    console.log('somehow you are placing a hold when you are not logged in. you should consider not doing that.')
  } else {
    $('.btn-hold-'+id).text('Placing Hold').addClass('disabled progress-bar progress-bar-striped progress-bar-animated');
    $.get("place_hold.js", {id: id, force: force_hold});
  }
}

function edit_hold(hid, id, action) {
  /* activate, suspend, cancel */
}
function bulk_edit_hold() {
}

function renew(cid, element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Renewing').addClass('disabled');
  $.post("renew_checkouts.js", {checkout_ids: cid});
}

function bulk_renew() {
}

function renew_all() {
  var checkoutIds = [];
  $('.renew-button').each(function() {
    checkoutIds.push($(this).data('checkout'));
  });

  alert(checkoutIds);
}

function toggle_select(element) {
  if ($(element).hasClass('select') == true) {
    $(element).removeClass('select btn-light').addClass('selected btn-success').html('<i class="fas fa-check"></i> Selected');
  } else {
    $(element).removeClass('selected btn-success').addClass('select btn-light').html('Select');
  }
}
