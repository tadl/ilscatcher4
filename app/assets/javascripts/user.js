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

  var parameters = {};

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
    parameters.pickup_library = pickup_library;
    parameters.default_search = default_search;
    parameters.keep_circ_history = keep_circ_history;
    parameters.keep_hold_history = keep_hold_history;
    parameters.circ_prefs_changed = true;
  }

  var username = encodeURIComponent($('#edit-pref-username').val());
  var hold_shelf_alias = encodeURIComponent($('#edit-pref-holdshelf-alias').val());
  var email = encodeURIComponent($('#edit-pref-email-address').val());

  var username_orig = encodeURIComponent($('#edit-pref-username').data('orig'));
  var hold_shelf_alias_orig = encodeURIComponent($('#edit-pref-holdshelf-alias').data('orig'));
  var email_orig = encodeURIComponent($('#edit-pref-email-address').data('orig'));

  var new_password = encodeURIComponent($('#edit-pref-new-password').val());
  var new_password2 = encodeURIComponent($('#edit-pref-new-password2').val());
  var current_password = encodeURIComponent($('#edit-pref-current-password').val());

  if (username != username_orig) {
    parameters.user_prefs_changed = true;
    parameters.username_changed = true;
    parameters.username = username;
    parameters.current_password = current_password;
  }
  if (hold_shelf_alias != hold_shelf_alias_orig) {
    parameters.user_prefs_changed = true;
    parameters.hold_shelf_alias_changed = true;
    parameters.hold_shelf_alias = hold_shelf_alias;
    parameters.current_password = current_password;
  }
  if (email != email_orig) {
    parameters.user_prefs_changed = true;
    parameters.email_changed = true;
    parameters.email = email;
    parameters.current_password = current_password;
  }
  if (new_password != "") {
    if (new_password == new_password2) {
      parameters.user_prefs_changed = true;
      parameters.password_changed = true;
      parameters.new_password = new_password;
      parameters.current_password = current_password;
    } else {
      console.log("passwords do not match");
    }

  }

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
    parameters.notify_prefs_changed = true;
    parameters.phone_notify_number = phone_notify_number;
    parameters.text_notify_number = text_notify_number;
    parameters.email_notify = email_notify;
    parameters.phone_notify = phone_notify;
    parameters.text_notify = text_notify;
  }

  if ((parameters.user_prefs_changed == true) && (current_password == "")) {
    $('#edit-pref-current-password').addClass('border-danger');
    $('#current-password-note').html('This field is required when making changes to User Preferences.');
    // probably include some help text, too
    $(element).html('Save').removeClass('disabled').prop('disabled', false);
  }

  if (Object.keys(parameters).length > 0) {
    $(element).html('<i class="fas fa-asterisk spin"></i> Saving...').addClass('disabled').prop('disabled', true);
    $.post('/update_preferences.js', parameters)
  } else {
    $('#cancel-preferences').click(); /* TODO need to test to be sure things are valid here and not just click cancel */
  }

}

function toggle_password_visible(element) {
  var form = $(element).data('element');
  var eye = $(element).data('eye');
  if ($(form).attr('type') == "text") {
    $(form).attr('type', 'password');
    $(eye).addClass('fa-eye-slash').removeClass('fa-eye');
  } else {
    $(form).attr('type', 'text');
    $(eye).addClass('fa-eye').removeClass('fa-eye-slash');
  }
}

function validate_sms(number) {
  $.ajax({
    url: 'https://util-ext.catalog.tadl.org/api/v1/lookup/' + number,
    dataType: 'json',
    xhrFields: {
      withCredentials: true,
    },
  })
  .done(function(data) {
    if (data.result) {
      //$('#text-notify-feedback').html("<span class='glyphicon glyphicon-flag text-danger'> We can't determine if this number is capable of receiving text messages.");
      $('#text-notify-feedback').removeClass().addClass('fas fa-flag text-warning');
    } else {
      if (data.carrier.type == 'mobile') {
        //$('#sms-check-result').text("<span class='glyphicon glyphicon-ok text-success'></span> This number appears capable of receiving text messages.");
        $('#text-notify-feedback').removeClass().addClass('fas fa-check text-success');
      } else {
        //$('#sms-check-result').text("<span class='glyphicon glyphicon-remove text-danger'></span> This number might not be able to receive text messages.");
        $('#text-notify-feedback').removeClass().addClass('fas fa-times text-danger');
      }
    }
  });
}
