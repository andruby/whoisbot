require 'bundler'
Bundler.require

problem_tlds = []
TLDS = Whois::Server.definitions[:tld].map(&:first).reject { |v| v.length > 5 } - problem_tlds

def css_for(tld, color)
  <<-EOS
<style type='text/css'>
  .#{tld.gsub('.','_')} { background-color: #{color}; color: white; font-weight: bold}
</style>
EOS
end

class Whoisbot < Goliath::API
  use Goliath::Rack::Params
  
  def on_close(env)
    env.logger.info "Connection closed."
  end
  
  def response(env)
    base_domain = params['query']
    if base_domain
      EM.defer do
        env.stream_send "<style type='text/css'>.box { float:left; width: #{(base_domain.length * 8) + 50}px; border: 1px solid black; padding: 3px} </style>"
        env.stream_send "<h3>Checking #{TLDS.count} tlds for base domain #{base_domain}</h3>"
        env.stream_send File.read(File.join(File.dirname(__FILE__), 'public', 'javascript.js'))
        env.stream_send "<div>"
        TLDS.each { |tld| env.stream_send "<div class='box #{tld.gsub('.','_')}' style=''>#{base_domain + tld}</div>" }
        env.stream_send "</div>"
        env.stream_send "<p>by <a href='http://twitter.com/andruby'>@andruby</a></p>"
        TLDS.each do |tld|
          begin
            if Whois.whois(base_domain + tld).properties[:available?]
              env.stream_send css_for(tld, 'green')
            else
              env.stream_send css_for(tld, 'red')
            end
          rescue => e
            env.stream_send css_for(tld, 'orange')
          end
        end
        env.stream_close
      end
      [200, {'Content-Type' => 'text/html'}, Goliath::Response::STREAMING]
    else
      response = ""
      response << File.read(File.join(File.dirname(__FILE__), 'public', 'javascript.js'))
      response << "<h4>Base Domain</h4>"
      response << "<form method='get'><input type='text' name='query'><input type='submit'></from>"
      response << "<p>by <a href='http://twitter.com/andruby'>@andruby</a></p>"
      [200, {'Content-Type' => 'text/html'}, response]
    end
  end
end