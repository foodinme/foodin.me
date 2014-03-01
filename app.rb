require 'sinatra'
require 'sass'
require 'haml'

class App < Sinatra::Base
  get '/main.css' do
    scss :main
  end

  get '/' do
    'We\'re coming.'
  end
end
