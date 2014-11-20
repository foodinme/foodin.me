require 'bundler'
Bundler.require

require 'sinatra/asset_pipeline'

class App < Sinatra::Base
  set :assets_precompile, %w(*.js *.css *.png *.jpg *.svg *.eot *.ttf *.woff)
  register Sinatra::AssetPipeline

  get '/*' do
    haml :index
  end
end
