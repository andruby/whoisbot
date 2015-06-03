var input = $('.search-input');
input.focus();
input.keypress(function(e) {
  if(e.which == 13) {
    $('.search').removeClass('virgin');
    var domain = input.val();
    var source = new EventSource('/whois/'+domain);
    source.addEventListener('available', function(e) {
      console.log(e.data);
    }, false);
    source.addEventListener('close', function(e) {
      source.close();
      console.log("connection closed");
    }, false);
  }
});
