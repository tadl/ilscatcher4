$(document).ready(function() {
  var owl = $('.owl-carousel');
  owl.owlCarousel({
    loop: false,
    margin: 10,
    nav: true,
    dots: true,
    mouseDrag: false,
    lazyLoad: true,
    navText : ['<i class="fa fa-angle-left" aria-hidden="true"></i>','<i class="fa fa-angle-right" aria-hidden="true"></i>'],
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
        items: 5,
        slideBy: 'page',
        margin: 20,
      },
    },
  });
});


