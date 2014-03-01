Bundler.require

require 'securerandom'
require 'sinatra/json'
require 'sequel'

class Session < Struct.new(:token, :store)
  def data
    store[token] ||= {}
  end

  def merge(new_data)
    store[token] = data.merge(new_data)
  end

  def stored_results?
    data[:results]
  end

  def store_results(results)
    merge results: results
  end

  def fetch_result(index)
    index = index.to_i % data[:results].length
    return data[:results][index], index, index+1
  end

  def to_json(*a)
    { token: token }.to_json(*a)
  end
end

class MemorySessionStore

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

class SequelSessionStore < MemorySessionStore

  class TableCache

    def initialize(table)
      @table = table
      @cache = {}
    end

    def [](key)
      @cache[key] ||= begin
        result = @table.first(key: key.to_s)
        if result
          YAML.load result[:data]
        else
          {}
        end
      end
    end

    def []=(key, val)
      key = key.to_s
      if @table.where(key: key).count > 0
        @table.where(key: key).update(data: YAML.dump(val))
      else
        @table.insert(key: key, data: YAML.dump(val))
      end
      @cache[key] = val
    end

  end

  def initialize(db)
    @data = TableCache.new(db[:sessions])
  end

end

if ENV['DATABASE_URL']
  db = Sequel.connect ENV['DATABASE_URL']
  SessionStore = SequelSessionStore.new db
else
  SessionStore = MemorySessionStore.new
end

class API < Sinatra::Base
  helpers Sinatra::JSON

  get '/gimme' do
    authenticate do |session|
      unless params[:id] && session.stored_results?
        session.store_results client.retrieve
      end
      
      result, this_id, next_id = session.fetch_result(params[:id])

      json "result"  => result.to_h,
           "meh"     => url("/gimme?id=#{next_id}&token=#{session.token}"),
           "yeah"    => {
             "url"    => url("/yeah"),
             "params" => "id=#{this_id}&token=#{session.token}",
           },
           "session" => session
    end
  end
  
  post '/yeah' do
    authenticate do |session|
      result, this_id, next_id = session.fetch_result(params[:id])

      json "result"  => result.to_h,
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
    SessionStore
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


