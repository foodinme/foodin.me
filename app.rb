require 'sinatra'

class App < Sinatra::Base
  get '/' do
    'We\'re coming.'
  end
end
