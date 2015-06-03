var input = $('.search-input');
input.focus();
input.keypress(function(e) {
  if(e.which == 13) {
    $('.search').removeClass('virgin');
    var domain = input.val();
    var source = new EventSource('/whois/'+domain);
    source.addEventListener('free', function(e) {
      console.log("Free: ", e.data);
    }, false);
    source.addEventListener('error', function(e) {
      console.log("Error: ", e.data);
    }, false);
    source.addEventListener('debug', function(e) {
      console.log(e.data);
    }, false);
    source.addEventListener('progress', function(e) {
      console.log('progress', e.data);
    }, false);
    source.addEventListener('close', function(e) {
      source.close();
      console.log("connection closed");
    }, false);
  }
});
