var input = $('.search-input');
input.focus();
input.keypress(function(e) {
  if(e.which == 13) {
    $('.search').removeClass('virgin');
  }
});
