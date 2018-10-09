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
function item_details(item, slider){
  var params = $.parseJSON(item)
  if(slider == true){
    params['from_slider'] = true
  }
  $.post("/details.js", params)
}

function missing_cover(item){
  var item = $.parseJSON(item)
  var icon_array = [['a','book','text'], 
                        ['c','music','notated music'], 
                        ['d','music','notated music'], 
                        ['e','globe-americas','cartographic'], 
                        ['f','globe-americas','cartographic'], 
                        ['g','film','moving image'], 
                        ['i','compact-disc','sound recording-nonmusical'], 
                        ['j','compact-disc','sound recording-musical'], 
                        ['k','image','still image'], 
                        ['m','save','software, multimedia'], 
                        ['o','briefcase','kit'], 
                        ['p','briefcase','mixed-material'], 
                        ['r','cube','three dimensional object'],
                        ['t','book','text']
                    ]
  icon = 'book'
  $.each(icon_array, function(index, value){
    if(value[2] == item['type_of_resource']){
      icon = value[1]
    } 
  });
  var target_div = '#item_cover_' + item['id']
  var target_div_details = target_div + '_details'
  var icon_base = '<i class="fas fa-'+ icon
  var icon_html_large = icon_base + ' fa-10x">' 
  $(target_div).html(icon_html_large)
  $(target_div_details).html(icon_html_large)
}

function check_blank_cover(image){
  if(image.naturalWidth == 1){
    $(image).trigger('error')
  } 
}

