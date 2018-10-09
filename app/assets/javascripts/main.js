$(document).ready(function() {
  $('.owl-carousel').owlCarousel({
    loop: true,
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
        loop: false,
        margin: 20
      }
    }
  });
});
