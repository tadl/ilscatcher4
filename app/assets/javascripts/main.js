$(document).ready(function() {
  var owl = $('.owl-carousel');
  owl.owlCarousel({
    loop: false,
    margin: 10,
    nav: false,
    dots: true,
    lazyLoad: true,
    responsiveClass: true,
    responsive: {
      0: {
        items: 1,
        dots: false,
      },
      600: {
        items: 3,
      },
      1000: {
        items: 5,
        margin: 20,
      },
    },
  });

  window.sliding = false;

  owl.on('drag.owl.carousel', function(event) {
    $('body').css('overflow', 'hidden');
    window.sliding = true;
  });

  owl.on('dragged.owl.carousel', function(event) {
    $('body').css('overflow', 'auto');
    setTimeout(function() {
      window.sliding = false;
    }, 10);
  });


});


