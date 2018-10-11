$(document).ready(function() {
  var owl = $('.owl-carousel');
  owl.owlCarousel({
    loop: false,
    margin: 5,
    nav: true,
    dots: true,
    mouseDrag: false,
    lazyLoad: true,
    responsiveClass: true,
    responsive: {
      0: {
        items: 2,
        nav: false,
        dots: false,
        slideBy: 'page',
        mouseDrag: true,
      },
      600: {
        items: 3,
        slideBy: 'page',
      },
      1000: {
        items: 6,
        slideBy: 'page',
        margin: 10,
      },
    },
  });
});


