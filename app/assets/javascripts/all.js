var ready = function(){
  //item details links fire onclick when clicked but follow link when opened in new tab
  $(document).on('click', '.item_details_link', function(e) {
    if (e.which == 1) {
      e.preventDefault();
    }
  });
}

$(document).ready(ready);


//open fancybox with item details
function item_details(item){
  var params = $.parseJSON(item)
  $.post("/details.js", params)
}