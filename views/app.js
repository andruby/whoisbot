$('.search input').keypress(function(e) {
  if(e.which == 13) {
    $('.search').removeClass('virgin');
  }
});
