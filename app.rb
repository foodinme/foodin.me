Bundler.require

require 'sinatra/asset_pipeline'

class App < Sinatra::Base
  register Sinatra::AssetPipeline

  get '/main.css' do
    scss :main
  end

  get '/' do
    haml :index
  end

  get '/food' do
    @food = {id: '1', category: 'cheetos', name: 'AM PM', address: '1110 SE Powell Blvd, Portland, OR 97202', rating: '5', source: 'foursquare'}
    rabl :food, format: 'json'
  end
end
