# Get the data file from http://s3.amazonaws.com/alexa-static/top-1m.csv.zip

require 'whois'
require 'csv'

sorted_tlds = Whois::Server.definitions[:tld].map(&:first).sort_by { |x| x.length * -1 }
top_tlds = Hash.new(0)

i = 0
CSV.foreach("data/top-1m.csv") do |row|
  domain = row[1]
  tld = sorted_tlds.detect { |tld| domain[-(tld.length)..-1] == tld }
  top_tlds[tld] += 1
  p i if (i+=1) % 20000 == 0
end

CSV.open("research/tld_top_1m.csv", "wb") do |csv|
  top_tlds.each do |tld, toppers|
    csv << [tld, toppers]
  end
end
