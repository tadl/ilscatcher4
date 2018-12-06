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


  /* circ prefs = all changed in one request, requires all values 
     if anything changes, do the thing. */
  var pickup_library = $('#edit-pref-pickup-library').val();
  var default_search = $('#edit-pref-default-search').val();
  var keep_circ_history = $('#edit-pref-keep-circ-history').prop('checked');
  var keep_hold_history = $('#edit-pref-keep-hold-history').prop('checked');

  /* user prefs = all changed as individual requests. requires current password be valid
     if anything changes, or new password supplied (with matching repeated) do the thing
     for each thing that changes */
  var username = encodeURIComponent($('#edit-pref-username').val());
  var hold_shelf_alias = encodeURIComponent($('#edit-pref-holdshelf-alias').val());
  var email = encodeURIComponent($('#edit-pref-email-address').val());
  var new_password = $('#edit-pref-new-password').val();
  var new_password2 = $('#edit-pref-new-password2').val();
  var current_password = $('#edit-pref-current-password').val();

  /* notify prefs = all changed in one request, requires all values
     if anything changes, do the thing. */
  var phone_notify_number = encodeURIComponent($('#edit-pref-phone-notify-number').val());
  var text_notify_number = encodeURIComponent($('#edit-pref-text-notify-number').val());
  var email_notify = $('#edit-pref-notify-method-email').prop('checked');
  var phone_notify = $('#edit-pref-notify-method-phone').prop('checked');
  var text_notify = $('#edit-pref-notify-method-text').prop('checked');





  /* for debugging */
  console.log(pickup_library);
  console.log(default_search);
  console.log(keep_circ_history);
  console.log(keep_hold_history);
  console.log(username);
  console.log(hold_shelf_alias);
  console.log(new_password);
  console.log(new_password2);
  console.log(current_password);
  console.log(phone_notify_number);
  console.log(text_notify_number);
  console.log(email_notify);
  console.log(phone_notify);
  console.log(text_notify);
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
