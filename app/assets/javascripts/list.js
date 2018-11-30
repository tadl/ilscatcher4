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
  $('.new-list').show();
  $('.list-info').hide();
}

function cancel_new_list() {
  $('.list-info').show();
  $('.new-list').hide();
}

function save_new_list(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Creating new list...').attr('disabled', true).addClass('disabled');
  var name = encodeURIComponent($('#new-list-title').val());
  var description = encodeURIComponent($('#new-list-description').val());
  var sharedTemp = $('#new-list-shared').prop('checked');
  var shared = (sharedTemp == true) ? 'yes' : 'no';
  $.post('/create_list.json', {name: name, description: description, shared: shared})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
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
  var noteid = $(element).data('noteid');
  var listitemid = $(element).data('listitemid');
  $('#edit-note-content-'+noteid+'-'+listitemid).val($('#note-content-'+noteid+'-'+listitemid).text());
  $('#note-'+noteid+'-'+listitemid).hide();
  $('#edit-note-'+noteid+'-'+listitemid).show();
  $('.btn-list-note-edit').attr('disabled', true).addClass('disabled');
}

function cancel_edit_list_item_note(element) {
  var noteid = $(element).data('noteid');
  var listitemid = $(element).data('listitemid');
  $('#note-'+noteid+'-'+listitemid).show();
  $('#edit-note-'+noteid+'-'+listitemid).hide();
  $('.btn-list-note-edit').attr('disabled', false).removeClass('disabled');
}

function save_edit_list_item_note(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Updating note...').attr('disabled', true).addClass('disabled');
  var noteid = $(element).data('noteid');
  var listid = $(element).data('listid');
  var listitemid = $(element).data('listitemid');
  var note = encodeURIComponent($('#edit-note-content-'+noteid+'-'+listitemid).val());
  $.post('/edit_note.json', {list_id: listid, note_id: noteid, note: note})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function delete_list_item_note(element) {
  var listid = $(element).data('listid');
  var noteid = $(element).data('noteid');
  $(element).attr('onclick', 'actually_delete_list_item_note(this)').removeClass('btn-primary').addClass('btn-danger').html('Confirm');
}

function actually_delete_list_item_note(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Deleting note...').attr('disabled', true).addClass('disabled');
  var noteid = $(element).data('noteid');
  var listid = $(element).data('listid');
  var note = '';
  $.post('/edit_note.json', {list_id: listid, note_id: noteid, note: note})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function new_list_item_note(element) {
  var listitemid = $(element).data('listitemid');
  $('#new-note-'+listitemid).show();
}

function cancel_new_list_item_note(element) {
  var listitemid = $(element).data('listitemid');
  $('#new-note-'+listitemid).hide();
}

function save_new_list_item_note(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Saving note...').attr('disabled', true).addClass('disabled');
  var listitemid = $(element).data('listitemid');
  var listid = $(element).data('listid');
  var notecontent = encodeURIComponent($('#new-note-content-'+listitemid).val());
  $.post('/add_note_to_list.json', {list_id: listid, list_item_id: listitemid, note: notecontent})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}

function remove_item_from_list(element) {
  $(element).attr('onclick', 'actually_remove_item_from_list(this)').removeClass('btn-primary').addClass('btn-danger').html('Confirm');
}

function actually_remove_item_from_list(element) {
  $(element).html('<i class="fas fa-asterisk spin"></i> Removing item...').attr('disabled', true).addClass('disabled');
  var listid = $(element).data('listid');
  var listitemid = $(element).data('listitemid');
  $.post('/remove_item_from_list.json', {list_id: listid, list_item_id: listitemid})
    .done(function(data) {
      if (data.message == 'success') {
        location.reload();
      } else {
        show_alert('danger', 'Something went wrong. Please try again.');
      }
    });
}
