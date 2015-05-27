# my_app.rb
require 'sinatra/base'

class Whoisbot < Sinatra::Base
  get '/' do
    "hi"
  end
end
