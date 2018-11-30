function edit_list_details(id) {
  $('#list-'+id).hide();
  $('#edit-list-'+id).show();
  $('.list-info').each(function() {
    $(this).find('button').attr('disabled', true).addClass('disabled');
  });
}

function cancel_edit_list(id) {
  $('#edit-list-'+id).hide();
  $('#list-'+id).show();
  $('button').attr('disabled', false).removeClass('disabled');
  $('.list-error').html('').hide();
}

function save_list_details(id, offset) {
  var name = encodeURIComponent($('#list-'+id+'-title').val());
  if (name == "") {
    $('#list-error-'+id).html('Your list must have a name.').show();
    return;
  }
  var description = encodeURIComponent($('#list-'+id+'-description').val());
  console.log('name: '+name+', id: '+id+', offset: '+offset+', description: '+description);
  $('#cancel-list-'+id).prop('disabled', true).addClass('disabled');
  $('#save-list-'+id).html('<i class="fas fa-asterisk spin"></i> Saving...').prop('disabled', true).addClass('disabled');
  $.post('/edit_list.json', {list_id: id, offset: offset, name: name, description: description})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        /* something went horribly wrong, alert the user */
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function delete_list(element) {
  var listid = $(element).data('listid');
  $(element).attr('onclick', 'actually_delete_list(this)').removeClass('btn-primary').addClass('btn-danger').html('Confirm');
}

function actually_delete_list(element) {
  var listid = $(element).data('listid');
  console.log(listid);
  $(element).html('<i class="fas fa-asterisk spin"></i> Deleting...').attr('disabled', true).addClass('disabled');
  $.post('/destroy_list.json', {list_id: listid})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function new_list() {
}

function save_new_list() {
}

function toggle_list_visibility(element, visibility) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Toggling share setting...').attr('disabled', true).addClass('disabled');
  var listid = $(element).data('listid');
  var offset = $(element).data('offset');
  var share = (visibility == 'Public') ? 'show' : 'hide';
  $.post('/share_list.json', {list_id: listid, offset: offset, share: share})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function set_list_default(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Setting default list...').attr('disabled', true).addClass('disabled');
  var listid = $(element).data('listid');
  $.post('/make_default_list.json', {list_id: listid})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function edit_list_item_note(element) {
}

function save_edit_list_item_note(element) {
}

function new_list_item_note(element) {
}

function save_new_list_item_note(element) {
}

function remove_item_from_list(element) {
}

function actually_remove_item_from_list(element) {
}

