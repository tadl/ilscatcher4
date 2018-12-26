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

  $('.autoload').on('change', function() {
    $('#search_button').click();
  });

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

  if ((username) && (password)) {
    $('#login-button').html('<i class="fas fa-asterisk spin"></i> One moment...').attr('disabled', true).addClass('disabled')
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

function place_hold(element, id, force, from_action) {
  var force_hold = (typeof force !== 'undefined') ? 'false' : 'true';
  var token = Cookies.get('login')
  if (token == null) {
    login_and_place_hold(id, from_action)
    return
  } else {
    $(element).html('<i class="fas fa-asterisk spin"></i> Placing Hold...').addClass('disabled').attr('disabled', true);
    $.post("place_hold.js", {id: id, force: force_hold, from_action: from_action});
  }
}

function show_change_pickup(element) {
  var hold_id = $(element).data('hold_id');
  var record_id = $(element).data('record_id');
  var from_action = $(element).data('from_action');
  var hold_status = $(element).data('hold_status');
  if (!hold_id) {
    $(element).html('<i class="fas fa-asterisk spin"></i> Loading pickup locations...').addClass('disabled').attr('disabled', true);
    $.get('/holds.json')
    .done(function(data) {
      if (data['holds']) {
        $.each(data['holds'], function(i, hold) {
          if (hold.id == record_id) {
            load_form(hold.hold_id, record_id, from_action, hold.hold_status);
          }
        });
      } else {
        show_alert('danger', 'Something unexpected happened. Please try again.');
      }
    });
  } else {
    load_form(hold_id, record_id, from_action, hold_status);
  }
}
function load_form(hold_id, record_id, from_action, hold_status) {
  var form = $('#hidden_change_pickup').html();
  if (from_action == 'from_details') {
    var hide_div = '.details-hold-button-' + record_id;
    var target_div = '#details-change-pickup-' + record_id;
  } else {
    var hide_div = '.list-hold-button-' + record_id;
    var target_div = '#list-change-pickup-' + record_id;
  }
  $(hide_div).hide();
  $(target_div).html(form).show();
  $(target_div).find('.change_pickup_button').addClass('change_pickup_button-'+record_id).removeClass('change_pickup_button');
  $(target_div).find('.cancel_change_pickup').addClass('cancel_change_pickup-'+record_id).removeClass('cancel_change_pickup').attr('data-record_id', record_id).attr('data-from_action', from_action);
  $(target_div).find('.dropdown-item').attr('data-hold_id', hold_id).attr('data-record_id', record_id).attr('data-from_action', from_action).attr('data-hold_status', hold_status);
}
function change_pickup_location(element) {
  var pickup_location = $(element).data('pickup_location');
  var hold_id = $(element).data('hold_id');
  var hold_status = $(element).data('hold_status');
  var from_action = $(element).data('from_action');
  var record_id = $(element).data('record_id');
  $('.cancel_change_pickup-'+record_id).addClass('disabled').attr('disabled', true);
  $('.change_pickup_button-'+record_id).html('<i class="fas fa-asterisk spin"></i> Changing pickup location...').addClass('disabled').attr('disabled', true);
  $.post("change_hold_pickup.js", {hold_id: hold_id, hold_status: hold_status, pickup_location: pickup_location, from_action: from_action });
}
function cancel_change_pickup(element) {
  var record_id = $(element).data('record_id');
  var from_action = $(element).data('from_action');
  if (from_action == 'from_details') {
    var target_div = '.details-hold-button-' + record_id;
    var hide_div = '#details-change-pickup-' + record_id;
  } else {
    var target_div = '.list-hold-button-' + record_id;
    var hide_div = '#list-change-pickup-' + record_id;
  }
  $('.change_pickup_button').html('Change pickup location').removeClass('disabled').attr('disabled', false);
  $(hide_div).empty().hide();
  $(target_div).show();
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
  if (action == "confirm") {
    $(element).html('Confirm Cancel Selected').removeClass('btn-light').addClass('btn-danger').attr('onclick', "bulk_edit_hold(this, 'cancel')");
    return;
  }
  var holdIds = []
  $('.selected').each(function() {
    holdIds.push($(this).data('hold'));
  });
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
  $('#bulk-hold-cancel').html('Cancel Selected').removeClass('btn-danger').addClass('btn-light').attr('onclick', "bulk_edit_hold(this, 'confirm')");
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
}

function add_to_list(element) {
  var list_id = $(element).data('list_id');
  var record_id = $(element).data('record_id');
  var button = $(element).data('button_id');
  var dropdown = $(element).data('dropdown_id');
  $(button).attr('disabled', true).addClass('disabled').html('<i class="fas fa-asterisk spin"></i> Adding...');
  $(dropdown).attr('disabled', true).addClass('disabled');
  $.post('/add_item_to_list.json', {list_id: list_id, record_id: record_id})
  .done(function(data) {
    if (data.message == 'success') {
      $(button).html("Added");
    } else {
      $(button).html('Error');
    }
  });
}

