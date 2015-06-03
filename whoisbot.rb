# my_app.rb
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/sse'
require 'whois'
require 'sass'

TLDS = Whois::Server.definitions[:tld].reject do |tld, host, ops|
  host.nil?
end.map(&:first)

class Whoisbot < Sinatra::Base
  include Sinatra::SSE

  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  get '/app.css' do
    scss :app
  end

  get '/app.js' do
    send_file File.join(settings.views, 'app.js')
  end

  get '/whois/:base' do
    base = params['base']
    tlds_to_go = TLDS.clone
    sse_stream do |sse|
      TLDS.each do |tld|
        domain = base + tld
        EM.defer do
          check_domain(domain, sse)
          track_progress(tld, tlds_to_go, sse)
        end
      end
    end
  end

  def track_progress(tld, tlds_to_go, sse)
    tlds_to_go.delete(tld)
    tlds_done = TLDS.count - tlds_to_go.count
    if tlds_to_go.count == 0
      sse.push event: "close", data: "finished"
      sse.close
    elsif tlds_done % 10 == 0
      sse.push event: 'progress', data: {done: tlds_done, total: TLDS.count}.to_json
    end
  end

  def check_domain(domain, sse, retries_left=10)
    if Whois.whois(domain).available?
      sse.push event: 'free', data: domain
    end
  rescue Whois::ConnectionError, Whois::ResponseIsThrottled => exception
    retry_check_domain(domain, sse, retries_left-2)
  rescue Timeout::Error => exception
    retry_check_domain(domain, sse, retries_left-5)
  rescue Exception => exception
    mark_error(domain, sse)
  end

  def retry_check_domain(domain, sse, retries_left)
    sleep 0.4
    # sse.push event: 'debug', data: "Retry: #{domain}"
    retries_left > 0 ? check_domain(domain, sse, retries_left) : mark_error(domain, sse)
  end

  def mark_error(domain, sse)
    sse.push event: 'error', data: domain
  end

end
