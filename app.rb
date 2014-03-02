Bundler.require

require 'sinatra/asset_pipeline'

class App < Sinatra::Base
  set :assets_js_compressor, :none
  register Sinatra::AssetPipeline

  get '/*' do
    haml :index
  end
end
