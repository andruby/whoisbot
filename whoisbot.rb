require 'bundler'
Bundler.require
require 'erb'

problem_tlds = []
TLDS = Whois::Server.definitions(:tld).map(&:first).reject { |v| v.length > 5 } - problem_tlds
NO_WHOIS_TLDS = Whois::Server.definitions(:tld).select { |tld, host, ops| host.nil? }.map(&:first)

class Helper
  def ref_link(domain, *tlds)
    "https://www.namecheap.com/domains/domain-name-search/results.aspx?domain=#{domain}&aff=35934&tlds=#{tlds.join(',')}"
  end
end

class SuperWho
  include Celluloid

  def color_for_domain(base, tld, env, retries = 10)
    domain = base + "." + tld
    color = Whois.whois(domain).parser.available? ? 'green' : 'red'
    env.template(:color, tld: tld, color: color)
  rescue Whois::ConnectionError, Whois::ResponseIsThrottled => exception
    retry_cfd(base, tld, env, retries, 2, exception)
  rescue Timeout::Error => exception
    retry_cfd(base, tld, env, retries, 5, exception)
  rescue Exception => exception
    mark_error(env, tld, exception)
  end

  def retry_cfd(base, tld, env, retries, penalty, e)
    sleep 0.4
    # env.stream_send "<br>Retry (#{retries} left) for [#{tld}]: #{e.class} #{e.message}"
    retries > 0 ? color_for_domain(base, tld, env, retries - penalty) : mark_error(env, tld, e)
  end

  def mark_error(env, tld, e)
    env.template(:color, tld: tld, color: '#ff9900')
    # env.stream_send "<br>Exception for [#{tld}]: #{e.class} #{e.message}"
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
      stream_send Tilt.new("templates/#{filename}.html.erb").render(Helper.new, locals || {})
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
      env.template(:head, :boxes, :credits, base_domain: base_domain, tlds: TLDS, ignore_tlds: NO_WHOIS_TLDS)
      pool = SuperWho.pool(size: 40)
      futures = (TLDS - NO_WHOIS_TLDS).map { |tld| pool.future(:color_for_domain, base_domain, tld, env) }
      futures.each(&:value)
      env.template(:foot)
      env.stream_close
    end
  end
end
