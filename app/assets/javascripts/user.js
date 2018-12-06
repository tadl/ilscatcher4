/* javascripts used in the user controller */
function edit_preferences() {
  $('#prefs-panel').hide();
  $('#edit-prefs-panel').show();
}

function cancel_edit_preferences() {
  $('#edit-prefs-panel').hide();
  $('#prefs-panel').show();
}

function save_preferences(element) {
/*
  element id                        preference              what it is
  #edit-pref-pickup-library         pickup_library          pickup library
  #edit-pref-default-search         default_search          default search location
  #edit-pref-keep-circ-history      keep_circ_history       keep search history option
  #edit-pref-keep-hold-history      keep_hold_history       keep hold history option (deprecated/hide?)
  #edit-pref-username               username                username
  #edit-pref-holdshelf-alias        hold_shelf_alias        holdshelf alias
  #edit-pref-email-address          email                   email address
  #edit-pref-new-password           *                       new password
  #edit-pref-new-password2          *                       new password again
  #edit-pref-current-password       *                       current password
  #edit-pref-phone-notify-number    phone_notify_number     phone notify number
  #edit-pref-text-notify-number     text_notify_number      text notify number
  #edit-pref-notify-method-email    email_notify            email notification method
  #edit-pref-notify-method-phone    phone_notify            phone notification method
  #edit-pref-notify-method-text     text_notify             text notification method

 */

  var circ_prefs_changed = false;

  var user_prefs_changed = false;
  var username_changed = false;
  var hold_shelf_alias_changed = false;
  var email_changed = false;
  var password_changed = false;

  var notify_prefs_changed = false;

  /* circ prefs = all changed in one request, requires all values 
     if anything changes, do the thing. */
  var pickup_library = $('#edit-pref-pickup-library').val();
  var default_search = $('#edit-pref-default-search').val();
  var keep_circ_history = $('#edit-pref-keep-circ-history').prop('checked');
  var keep_hold_history = $('#edit-pref-keep-hold-history').prop('checked');

  var pickup_library_orig = $('#edit-pref-pickup-library').data('orig');
  var default_search_orig = $('#edit-pref-default-search').data('orig');
  var keep_circ_history_orig = $('#edit-pref-keep-circ-history').data('orig');
  var keep_hold_history_orig = $('#edit-pref-keep-hold-history').data('orig');

  if (
    (pickup_library != pickup_library_orig) ||
    (default_search != default_search_orig) ||
    (keep_circ_history != keep_circ_history_orig) ||
    (keep_hold_history != keep_hold_history_orig)
  ) {
    circ_prefs_changed = true;
    console.log('circ prefs changed');
  } else {
    console.log('circ prefs did not change');
  }


/* user prefs = all changed as individual requests. requires current password be valid
     if anything changes, or new password supplied (with matching repeated) do the thing
     for each thing that changes */
  var username = encodeURIComponent($('#edit-pref-username').val());
  var hold_shelf_alias = encodeURIComponent($('#edit-pref-holdshelf-alias').val());
  var email = encodeURIComponent($('#edit-pref-email-address').val());

  var username_orig = encodeURIComponent($('#edit-pref-username').data('orig'));
  var hold_shelf_alias_orig = encodeURIComponent($('#edit-pref-holdshelf-alias').data('orig'));
  var email_orig = encodeURIComponent($('#edit-pref-email-address').data('orig'));

  var new_password = $('#edit-pref-new-password').val();
  var new_password2 = $('#edit-pref-new-password2').val();
  var current_password = $('#edit-pref-current-password').val();

  if (username != username_orig) {
    username_changed = true;
    user_prefs_changed = true;
    console.log('username changed');
  } else {
    console.log('username did not change');
  }
  if (hold_shelf_alias != hold_shelf_alias_orig) {
    hold_shelf_alias_changed = true;
    user_prefs_changed = true;
    console.log('holdshelf alias changed');
  } else {
    console.log('holdshelf alias did not change');
  }
  if (email != email_orig) {
    email_changed = true;
    user_prefs_changed = true;
    console.log('email changed');
  } else {
    console.log('email did not change');
  }

  if (new_password != "") {
    console.log('password changed');
  } else {
    console.log('password did not change');
  }

  if ((user_prefs_changed == true) && (current_password == "")) {
    $('#edit-pref-current-password').addClass('border-danger');
    // probably include some help text, too
    console.log('a user pref changed but current password was blank');
  }


  /* notify prefs = all changed in one request, requires all values
     if anything changes, do the thing. */
  var phone_notify_number = encodeURIComponent($('#edit-pref-phone-notify-number').val());
  var text_notify_number = encodeURIComponent($('#edit-pref-text-notify-number').val());
  var email_notify = $('#edit-pref-notify-method-email').prop('checked');
  var phone_notify = $('#edit-pref-notify-method-phone').prop('checked');
  var text_notify = $('#edit-pref-notify-method-text').prop('checked');

  var phone_notify_number_orig = encodeURIComponent($('#edit-pref-phone-notify-number').data('orig'));
  var text_notify_number_orig = encodeURIComponent($('#edit-pref-text-notify-number').data('orig'));
  var email_notify_orig = $('#edit-pref-notify-method-email').data('orig');
  var phone_notify_orig = $('#edit-pref-notify-method-phone').data('orig');
  var text_notify_orig = $('#edit-pref-notify-method-text').data('orig');

  if (
    (phone_notify_number != phone_notify_number_orig) ||
    (text_notify_number != text_notify_number_orig) ||
    (email_notify != email_notify_orig) ||
    (phone_notify != phone_notify_orig) ||
    (text_notify != text_notify_orig)
  ) {
    notify_prefs_changed = true;
    console.log('notify prefs changed');
  } else {
    console.log('notify prefs did not change');
  }


}

function validate_sms(element) {
  var TADL_LAST_NUMBER;
  var digits = element.value.replace(/\D/g, '');
  var digits_trimmed = digits.replace(/^1/, '');
  if (digits_trimmed.length == 10) {
    if (TADL_LAST_NUMBER !== digits_trimmed) {
      TADL_LAST_NUMBER = digits_trimmed;
      $.ajax({
        url: 'https://util-ext.catalog.tadl.org/api/v1/lookup/' + digits_trimmed,
        dataType: 'json',
        xhrFields: {
          withCredentials: true,
        },
      })
      .done(function(data) {
        if (data.result) {
          $('#sms_check_result').text("<span class='glyphicon glyphicon-flag text-danger'> We can't determine if this number is capable of receiving text messages.");
        } else {
          if (data.carrier.type === 'mobile') {
            $('#sms_check_result').text("<span class='glyphicon glyphicon-ok text-success'></span> This number appears capable of receiving text messages.");
          } else {
            $('#sms_check_result').text("<span class='glyphicon glyphicon-remove text-danger'></span> This number might not be able to receive text messages.");
          }
        }
      });
    }
  }
}
