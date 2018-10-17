var $grid = $('.grid').masonry({
  columnWidth: '.grid-sizer',
  itemSelector: '.grid-item',
  percentPosition: true,
});

$grid.imagesLoaded().progress(function() {
  console.log('progress');
  $grid.masonry('layout');
});

