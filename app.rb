require 'sinatra'
require 'sass'
require 'haml'

class App < Sinatra::Base
  get '/main.css' do
    scss :main
  end

  get '/' do
    haml :index
  end
end
