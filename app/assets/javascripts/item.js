function show_marc(self, id){
 $(self).text('Loading MARC Record...').addClass('disabled');
 $.post("marc_record.js", {id: id}); 
}