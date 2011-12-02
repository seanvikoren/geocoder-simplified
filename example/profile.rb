# encoding: utf-8

require "redis"

REDIS_0 = Redis.new

class Api
  def get_16bit_hash(s)
    # Starting from 0xFFFF, overlay each byte, alternating on the low and high bytes using xor
    s.bytes.each_with_index.map{|c,i| c << ((i & 1) * 8)}.inject(0xFFFF){|hash, n| hash ^ n}
  end

  def id_from_string(s)
    "%04x" % get_16bit_hash(s)
  end

  def initialize(name, key, max_calls_per_day, priority)
    @id     = id_from_string(s)
    @fields = Hash.new
    load if @id
  end
  def initialize
    @name = name
    @symbol = name.underscore.to_sym
    @key = key
    @max_calls_per_day = max_calls_per_day
    @priority = priority
    @record = GeoApi.setup_record(name, key, max_calls_per_day, priority)
  end
  def setup_record(name, key, max_calls_per_day, priority)
    api = Api.find(:first, :conditions => { :name => name + POSTFIX })
    if api.nil?
      new_record = { :name => name + POSTFIX, :key => key, :max_count => max_calls_per_day, :priority => priority, :enabled => true, :usable => true }
      api = Api.create(:attributes => new_record)
    end
    return api
  end

  attr_reader :id

  def method_missing(meth, *args, &blk)
    if meth.to_s =~ /\A(\w+)=/
      @fields[$1] = args.first
    else
      @fields[meth]
    end
  end

  def load
    keys    = REDIS_0.keys("user:#{@id}:*")
    values  = REDIS_0.mget(*keys)
    @fields = Hash[*keys.map { |k| k[/\w+\z/] }.zip(values).flatten]
  end

  def save
    @id ||= REDIS_0.incr("global:next_user_id")
    REDIS_0.pipelined do |commands|
      @fields.each do |k, v|
        commands["user:#{@id}:#{k}"] = v
      end
    end
  end

  def inspect
    "<#User:#{@id} #{@fields.map { |k, v| "#{k}:#{v.inspect}" }.join(' ')}>"
  end
end

Api.new  # => <#User:1 username:"JEG2" password:"secret">

new_guy = User.new
new_guy.username = "New Guy"
new_guy.password = "123"
new_guy.save

User.new(new_guy.id)  # => <#User:31 username:"New Guy" password:"123">

if __FILE__ == "DO NOT RUN" # $0
  $:.push File.expand_path("../../lib", __FILE__)

  require 'geocoder'
  require 'redis'

  # redis = Redis.new
  # redis.set "foo", "bar"
  # p redis.get "foo"

  [
    "New York Metro, NY",
    "San Francisco, CA",
    "Reno, NV, USA",
    "Peoria",
    "Madrid, Spain",
    "London, England"
  ].each do |place_name|
    latitude, longitude = GeocoderSimplified.locate(place_name)
    puts "% 35s: latitude = %0.8f, longitude = %0.8f" % [place_name, latitude, longitude]
  end

end





























