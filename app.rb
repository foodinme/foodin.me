Bundler.require

require 'sinatra/asset_pipeline'

class App < Sinatra::Base
  set :assets_js_compressor, :none
  set :assets_precompile, %w(application.js main.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  register Sinatra::AssetPipeline

  get '/*' do
    haml :index
  end
end
