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
end
