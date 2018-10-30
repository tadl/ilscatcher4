var ready = function(){
  /* item details links fire onclick when clicked but follow link when opened in new tab */
  $(document).on('click', '.item_details_link', function(e) {
    if (e.which == 1) {
      e.preventDefault();
    }
  });
  
  // load salvattore
  $.getScript('/assets/salvattore.min.js');

  // left and right arrows to move between items
  var take_a_break = false
  $(document).keydown(function(e){
    if (e.which == 37 && $('.previous_link').is(':visible')){ 
        if(take_a_break == false){
          take_a_break = true
          setTimeout(function() { take_a_break = false }, 500);
          $('.previous_link').click()
          
        }
    }
    if (e.which == 39 && $('.next_link').is(':visible')){ 
      if(take_a_break == false){
        take_a_break = true
        setTimeout(function() { take_a_break = false }, 500);
        $('.next_link').click()
      }
    }
  });

  var windowWidth = $(window).width();
  if (windowWidth <= 768) {
    $('.collapse').collapse('hide');
  }
}

$(document).ready(ready);


/* open fancybox with item details */
function item_details(id, from, order, location_id) {
  var params = {};
  if (from) {
    params['from'] = from
  }
  if (order) {
    params['order'] = order
  }
  if (location_id) {
    params['location'] = location_id
  }
  params['id'] = id;
  $.post("/details.js", params);
}

function missing_cover(id, type) {
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
                        ['t','book','text'],
                    ]
  icon = 'book';
  $.each(icon_array, function(index, value) {
    if (value[2] == type) {
      icon = value[1];
    }
  });
  var target_div_list = '#item_cover_' + id;
  var target_div_grid = '#grid_item_cover_' + id;
  var target_div_details = target_div_list + '_details';
  var icon_base = '<i class="fas fa-'+ icon;
  //Use this size of icon for gird and details
  var icon_html_grid_details = icon_base + ' fa-10x"></i>';
  //Use a small and large icon for list display and only show right sized based on breakpoint
  var icon_html_large_list = icon_base + ' fa-10x d-block d-sm-none"></i>';
  var icon_html_small_list = icon_base + ' fa-7x d-none d-sm-block"></i>';
  var icon_html_both_list = icon_html_large_list + icon_html_small_list
  //Put the right html into the right div
  $(target_div_list).html(icon_html_both_list);
  $(target_div_details).html(icon_html_grid_details);
  $(target_div_grid).html(icon_html_grid_details);
}

function check_blank_cover(image) {
  if (image.naturalWidth == 1) {
    $(image).trigger('error');
  }
}

