Bundler.require
require 'sinatra/json'

class API < Sinatra::Base
  helpers Sinatra::JSON

  get '/gimme' do
    results = client.retrieve

    json "results" => results.map(&:to_h)
  end

  private

  def client
    @client ||= begin
      Burgatron::Client.new.tap do |client|
        client.add_source Burgatron::Sources::Canned.new(path: "canned.yml")
      end
    end
  end

end

class Struct

  def to_h
    each_pair.inject({}) do |h,(k,v)|
      h[k] = v
      h
    end
  end

end


