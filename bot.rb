require 'whois'

problem_tlds = []
TLDS = Whois::Server.definitions[:tld].map(&:first).reject { |v| v.length > 5 } - problem_tlds
base_domain = ARGV[0]
raise "No domain given" unless base_domain.is_a?(String) && base_domain.length > 1
@available = []
@errors = []

puts "Checking #{TLDS.count} tlds"

TLDS.each do |tld|
  begin
    print '.'
    STDOUT.flush
    domain = base_domain + tld
    if Whois.whois(domain).properties[:available?]
      @available << domain
    end
  rescue => e
    puts "error: #{e.message}"
    @errors << domain
  end
end

puts "Unknown status:"
puts @errors.map { |dom| "* \e[31m#{dom}\e[0m" }.join("\n")

puts "Domains available:"
puts @available.map { |dom| "* \e[32m#{dom}\e[0m" }.join("\n")
