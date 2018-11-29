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

function show_login_form(){
  var form = $('#hidden_login').html()
  $('#hidden_login').html('')
  $.fancybox.open({
    src  : '<div id="login_container" style="max-width: 400px; width: 100%;">'+ form +'</div>',
    type : 'inline',
    opts : {
      beforeClose : function( instance, current ) {
        $('#hidden_login').html(form)
      }
    }
  });
}

function do_login(f) {

  var username = f.username.value
  var password = f.password.value
  var from_action = f.from_action.value
  var target_hold = f.target_hold.value

  if (username != "" && password != "") {
    $.post("login.js", {username: username, password: password, from_action: from_action, target_hold: target_hold});
    $('#login-message').text('');
  } else {
    $('#login-message').text('Please specify username and password');
  }


  return false;


}

function login_and_place_hold(id, from_action){
  $.post("login_and_place_hold.js",{target_hold: id, from_action: from_action});
}

function do_logout() {
  $.post("logout.js");
}

function request_password_reset(){
  $.post("request_password_reset.js?fancybox=true");
}

function place_hold(id, force, from_action) {
  var force_hold = (typeof force !== 'undefined') ? 'true' : 'false';
  var token = Cookies.get('login')
  if (token == null) {
    login_and_place_hold(id, from_action)
    return
  } else {
    $('.btn-hold-'+id).text('Placing Hold').addClass('disabled progress-bar progress-bar-striped progress-bar-animated');
    $.post("place_hold.js", {id: id, force: force_hold});
  }
}

function cancel_confirm(element) {
  $(element).html('Confirm Cancel').removeClass('btn-primary').addClass('btn-danger').attr('onclick', 'edit_hold(this,"cancel")');
}
function edit_hold(element, action) {
  var holdId = $(element).data('hold');
  $(element).html('<i class="fas fa-asterisk spin"></i> One moment...').addClass('disabled').prop('disabled', true);
  $.post("manage_hold.js", {hold_id: holdId, task: action.toLowerCase()});
}
function bulk_edit_hold(element, action) {
  var holdIds = []
  $('.selected').each(function() {
    holdIds.push($(this).data('hold'));
  });
  console.log(holdIds);
  console.log(holdIds.length);
  if (holdIds.length > 0) {
    $('.bulk-action').addClass('disabled').prop('disabled', true);
    $(element).html('<i class="fas fa-asterisk spin"></i> One moment...');
    $.post("manage_hold.js", {hold_id: holdIds.join(), task: action});
  }
}

function renew(cid, element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Renewing').addClass('disabled').prop('disabled', true);
  $.post("renew_checkouts.js", {checkout_ids: cid});
}
function bulk_renew() {
  var checkoutIds = [];
  $('.selected').each(function() {
    checkoutIds.push($(this).data('checkout'));
  });
  if (checkoutIds.length > 0) {
    $('.bulk-action').html('<i class="fas fa-asterisk spin"></i> Renewing selected items').addClass('disabled').prop('disabled', true);
    $.post("renew_checkouts.js", {checkout_ids: checkoutIds.join()});
  } else {
    show_alert('warning', 'You must select one or more items to renew.');
  }
}
function renew_all() {
  var checkoutIds = [];
  $('.renew-button').each(function() {
    checkoutIds.push($(this).data('checkout'));
  });
  if (checkoutIds.length > 0) {
    $('.all-renew').html('<i class="fas fa-asterisk spin"></i> Renewing all items').addClass('disabled').prop('disabled', true);
    $.post("renew_checkouts.js", {checkout_ids: checkoutIds.join()});
  } else {
    show_alert('warning', 'Sorry, you have no items eligible for renewal.');
  }
}

function toggle_select(element) {
  if ($(element).hasClass('select') == true) {
    $(element).removeClass('select btn-light').addClass('selected btn-success').html('<i class="fas fa-check"></i> Selected');
    $('.bulk-action').removeClass('disabled').prop('disabled', false);
  } else {
    $(element).removeClass('selected btn-success').addClass('select btn-light').html('Select');
    $('.bulk-action').addClass('disabled').prop('disabled', true);
  }
}
function select_all() {
  var selectCount = 0;
  $('.select').each(function() {
    selectCount++;
    $(this).removeClass('select btn-light').addClass('selected btn-success').html('<i class="fas fa-check"></i> Selected');
  });
  if (selectCount > 0) {
    $('.bulk-action').removeClass('disabled').prop('disabled', false);
  }
}
function select_clear() {
  $('.bulk-action').addClass('disabled').prop('disabled', true);
  $('.selected').each(function() {
    $(this).removeClass('selected btn-success').addClass('select btn-light').html('Select');
  });
}

function show_alert(type, message) {
  alert_div = '#alert-box';
  var html = '<div class="alert alert-' + type + ' alert-dismissible fade show" role="alert">';
  html += message;
  html += '<button type="button" class="close" data-dismiss="alert" aria-label="Close">';
  html += '<span aria-hidden="true">&times;</span>';
  html += '</button>';
  html += '</div>';
  $(alert_div).append(html);
  console.log(html);
}