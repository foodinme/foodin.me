require './app'
require './api'

run Rack::URLMap.new(
  "/"    => App.new,
  "/api" => API.new
)