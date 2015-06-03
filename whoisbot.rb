# my_app.rb
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/sse'
require 'whois'

TLDS = Whois::Server.definitions[:tld].reject { |tld, host, ops| host.nil? }.map(&:first)

class Whoisbot < Sinatra::Base
  include Sinatra::SSE

  configure :development do
    register Sinatra::Reloader
  end

  get '/' do
    erb :index
  end

  get '/whois/:base' do
    base = params['base']
    sse_stream do |out|
      EM::Iterator.new(TLDS, 50).each(
        Proc.new do |tld, iter|
          domain = base + tld
          if Whois.whois(domain).available?
            out.push event: "available", data: domain
          end
          iter.next
        end,
        Proc.new do
          out.push event: "close", data: "finished"
          out.close
        end
      )
    end
  end

  get '/app.css' do
    scss :app
  end

  get '/app.js' do
    send_file File.join(settings.views, 'app.js')
  end
end
