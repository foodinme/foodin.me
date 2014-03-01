Bundler.require

require 'securerandom'
require 'sinatra/json'

class SessionStore

  class Session < Struct.new(:token, :store)
    def data
      store[token] ||= {}
    end

    def stored_results?
      data[:results]
    end

    def store_results(results)
      data[:results] = results
    end

    def fetch_result(index)
      index = index.to_i % data[:results].length
      return data[:results][index], index+1
    end

    def to_json(*a)
      { token: token }.to_json(*a)
    end
  end

  def initialize
    @data = {}
  end

  def start(token = nil)
    token = generate_token if token.nil? or token.empty?
    Session.new(token, @data)
  end

  private

  def generate_token
    SecureRandom.hex
  end

end

class API < Sinatra::Base
  helpers Sinatra::JSON

  get '/gimme' do
    authenticate do |session|
      unless params[:next] && session.stored_results?
        session.store_results client.retrieve
      end
      
      result, next_id = session.fetch_result(params[:next])

      json "result"  => result.to_h,
           "next"    => url("/gimme?next=#{next_id}&token=#{session.token}"),
           "session" => session
    end
  end

  private

  def client
    @client ||= begin
      Burgatron::Client.new.tap do |client|
        client.add_source Burgatron::Sources::Canned.new(path: "canned.yml")
      end
    end
  end

  def sessions
    @@sessions ||= SessionStore.new
  end

  def authenticate(&blk)
    yield sessions.start(params[:token])
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


