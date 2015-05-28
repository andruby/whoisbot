# my_app.rb
require 'sinatra/base'
require 'sinatra/reloader'

class Whoisbot < Sinatra::Base
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
end
