var input = $('.search-input');
var progress = $('.progress');
var results = $('.results')
input.focus();
input.keypress(function(e) {
  if(e.which == 13) {
    $('.search').removeClass('virgin');
    var domain = input.val();
    var source = new EventSource('/whois/'+domain);
    source.addEventListener('free', function(e) {
      results.append('<div class="free">'+e.data+'</div> ');
    }, false);
    source.addEventListener('error', function(e) {
      console.log("Error: ", e.data);
    }, false);
    source.addEventListener('debug', function(e) {
      console.log(e.data);
    }, false);
    source.addEventListener('progress', function(e) {
      data = jQuery.parseJSON(e.data);
      percent = Math.round((data.done / data.total)*100);
      progress.html(percent + '%');
    }, false);
    source.addEventListener('close', function(e) {
      source.close();
      console.log("connection closed");
    }, false);
  }
});
