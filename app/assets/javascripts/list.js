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
  var name = $('#list-'+id+'-title').val();
  if (name == "") {
    $('#list-error-'+id).html('Your list must have a name.').show();
    return;
  }
  var description = $('#list-'+id+'-description').val();
  console.log('name: '+name+', id: '+id+', offset: '+offset+', description: '+description);
  $('#cancel-list-'+id).prop('disabled', true).addClass('disabled');
  $('#save-list-'+id).html('<i class="fas fa-asterisk spin"></i> Saving...').prop('disabled', true).addClass('disabled');
  $.post('/edit_list.js', {list_id: id, offset: offset, name: name, description: description});
}

function delete_list(element) {
  var listid = $(element).data('listid');
  $(element).attr('onclick', 'actually_delete_list(this)').removeClass('btn-primary').addClass('btn-danger').html('Confirm');
}

function actually_delete_list(element) {
  var listid = $(element).data('listid');
  console.log(listid);
  $(element).html('<i class="fas fa-asterisk spin"></i> Deleting...').attr('disabled', true).addClass('disabled');
}

function toggle_list_visibility(element, newstatus) {
}

function set_list_default(element) {
}
