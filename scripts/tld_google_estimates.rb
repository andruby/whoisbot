require 'google-search'
require 'whois'
require 'csv'

def google_estimate(tld)
  Google::Search::Web.new(query: "site:#{tld}").response.estimated_count
end

i=0
CSV.open("research/tld_google_estimates.csv", "wb") do |csv|
  csv << ['tld', 'google estimated count']
  Whois::Server.definitions[:tld].each do |tld, host, ops|
    estimate = google_estimate(tld)
    csv << [tld, estimate]
    p i if (i+=1) % 100 == 0
  end
end
