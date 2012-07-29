require 'bundler'
Bundler.require

problem_tlds = []
TLDS = Whois::Server.definitions[:tld].map(&:first).reject { |v| v.length > 5 } - problem_tlds

class SuperWho
  include Celluloid

  def color_for_domain(base, tld, env)
    domain = base + tld
    color = Whois.whois(domain).available? ? 'green' : 'red' rescue 'orange'
    env.css_for(tld, color)
    true
  end
end

class EnvWrapper
  include Celluloid

  def initialize(env)
    @env = env
  end

  def css_for(tld, color)
    stream_send <<-EOS
  <style type='text/css'>
    .#{tld.gsub('.','_')} { background-color: #{color}; color: white; font-weight: bold}
  </style>
  EOS
  end

  def stream_send(txt)
    @env.stream_send(txt)
  end

  def stream_close
    @env.stream_close
  end
end

class Whoisbot < Goliath::API
  use Goliath::Rack::Params

  def on_close(env)
    env.logger.info "Connection closed."
  end

  def response(env)
    e = EnvWrapper.new(env)
    if (base_domain = params['query'])
      [200, {'Content-Type' => 'text/html'}, Goliath::Response::STREAMING]
      e.stream_send "<style type='text/css'>.box { float:left; width: #{(base_domain.length * 8) + 50}px; border: 1px solid black; padding: 3px} </style>"
      e.stream_send "<h3>Checking #{TLDS.count} tlds for base domain #{base_domain}</h3>"
      e.stream_send "<div>"
      TLDS.each { |tld| e.stream_send "<div class='box #{tld.gsub('.','_')}' style=''>#{base_domain + tld}</div>" }
      e.stream_send "</div>"
      e.stream_send "<div style='clear: both'>by <a href='http://twitter.com/andruby'>@andruby</a></div>"
      pool = SuperWho.pool(size: 50)
      futures = TLDS.map { |tld| pool.future(:color_for_domain, base_domain, tld, e) }
      EM.defer do
        futures.each { |f| f.value }
        e.stream_close
      end
    else
      response = ""
      response << "<h4>Base Domain</h4>"
      response << "<form method='get'><input type='text' name='query'><input type='submit'></from>"
      response << "<p>by <a href='http://twitter.com/andruby'>@andruby</a></p>"
      [200, {'Content-Type' => 'text/html'}, response]
    end
  end
end