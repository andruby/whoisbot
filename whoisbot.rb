require 'bundler'
Bundler.require
require 'erb'

problem_tlds = []
TLDS = Whois::Server.definitions[:tld].map(&:first).reject { |v| v.length > 5 } - problem_tlds

class SuperWho
  include Celluloid

  def color_for_domain(base, tld, env)
    domain = base + tld
    color = Whois.whois(domain).available? ? 'green' : 'red' rescue 'orange'
    env.template(:color, tld: tld, color: color)
    true
  end
end

class EnvWrapper
  include Celluloid

  def initialize(env)
    @env = env
  end

  def stream_send(txt)
    @env.stream_send(txt)
  end

  def stream_close
    @env.stream_close
  end

  def template(*filenames)
    locals = filenames.pop if filenames.last.is_a?(Hash)
    filenames.each do |filename|
      stream_send Tilt.new("templates/#{filename}.html.erb").render(Object.new, locals || {})
    end
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
      query(e, base_domain)
    else
      root(e)
    end
    [200, {'Content-Type' => 'text/html'}, Goliath::Response::STREAMING]
  end

  def root(env)
    EM.defer do
      env.template(:head, :root, :credits, :foot)
      env.stream_close
    end
  end

  def query(env, base_domain)
    EM.defer do
      env.template(:head, :boxes, :credits, base_domain: base_domain, tlds: TLDS)
      pool = SuperWho.pool(size: 50)
      futures = TLDS.map { |tld| pool.future(:color_for_domain, base_domain, tld, env) }
      futures.each(&:value)
      env.template(:foot)
      env.stream_close
    end
  end
end