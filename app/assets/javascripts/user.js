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
}

function validate_sms(element) {
  var TADL_LAST_NUMBER;
  var digits_trimmed;
  var original = element.value;
  var digits = element.value.replace(/\D/g, '');
  digits_trimmed = digits.replace(/^1/, '');
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
