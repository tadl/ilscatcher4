function show_marc(self, id){
 $(self).html('<i class="fas fa-asterisk spin"></i> Loading MARC...').addClass('disabled').prop('disabled', true);
 $.post("marc_record.js", {id: id}); 
}
