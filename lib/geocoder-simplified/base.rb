# encoding: utf-8

# holy grail of redis info:
# http://dev.mensfeld.pl/2011/11/using-redis-as-a-temporary-cache-for-data-shared-by-multiple-independent-processes/

# monkeypatch ruby from the rails underscore addition to String
class String
  def underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
end

class Util
  require 'stringio'

  MAX_INT32 = 0x7fffffff
  SECONDS_PER_DAY = 4 * 60 * 60

  class << self
    def capture_stderr
      previous_stderr, $stderr = $stderr, StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = previous_stderr
    end
  end
end

class GeocoderSimplified
  $:.push File.expand_path("..", __FILE__)

  require 'geocoder'
  require 'redis'
  require 'configuration'
  require 'redis_expiring_counter'

  include Comparable


  POSTFIX = "Geocode"
  UNLIMITED_CALLS = Util::MAX_INT32

  @@api_list = []

  class GeocoderApi# < RedisTable
    attr_reader :id, :counter, :name, :key, :max_calls_per_day, :priority, :symbol
    # we will need to store the counters here for restart accuracy
    # we will use a simple overwrite if it already exists...if it iexists, we may wish to only set the key, count, and priority
    def initialize(name, key, max_calls_per_day)
      # we will use the name to generate an id
      full_name = name + POSTFIX
      @id = get_16bit_hash_id(full_name)
      #super (@id.to_i(16)) # the load happens here
      @name = full_name
      @key = key
      @max_calls_per_day = max_calls_per_day
      @symbol = name.underscore.to_sym
      @db_key = "#{self.class.to_s}:#{full_name}:counter_db_id"

      if @@db.exists(@db_key)
        counter_db_id = @@db[@db_key]
        @counter = RedisExpiringCounter.new(Util::SECONDS_PER_DAY, max_calls_per_day, counter_db_id)
      else
        @counter = RedisExpiringCounter.new(Util::SECONDS_PER_DAY, max_calls_per_day)
        @@db[@db_key] = @counter.db_index
      end
    end

    def get_16bit_hash_id(s)
      "%04x" % s.bytes.each_with_index.map{|c,i| c << ((i & 1) * 8)}.inject(0xFFFF){|hash, n| hash ^ n}
    end

    def set_this_api
      Geocoder::Configuration.lookup = @symbol
    end

    def count
      @counter.count
    end

    def dump
      @counter.dump
    end

    def locate(place_name)
      location = []
      latitude = 0.0
      longitude = 0.0

      set_this_api

      begin
        warning_text = Util.capture_stderr do
          location = Geocoder.search(place_name)
          increment_count
        end
        # Write sucess to log here
        #Rails.logger.warn "Geocoder: " + warning_text if warning_text != ""
      rescue StandardError => e
        # Write fail to log here
        #Rails.logger.error "Geocoder: " + @name + ": "+ e.to_s
      end

      if not (location.nil? or location.count == 0)
        latitude = location.first.latitude
        longitude = location.first.longitude
      end

      return latitude, longitude
    end

    class << self
      @@db = Redis.new({:db => 0, :host => Configuration::HOST, :port => Configuration::DB_PORT})
    end
  end

  class << self
    @@db = Redis.new(:db => 1)
    # Attach the default goecoding apis, _in order_
    key = ""
    #Redis.new.flushall

    @@api_list << GeocoderApi.new("GeocoderCa", key, UNLIMITED_CALLS)
    @@api_list << GeocoderApi.new("Google", key, 3)#2500)
    @@api_list << GeocoderApi.new("Yahoo", key, 50000)
    @@api_list.each{|api| puts "#{api.count}:#{api.symbol}"}

    def get_counts
      @@api_list.each.inject({}){|h,api| h.update(api.symbol => api.count)}
    end

    def locate(place_name)
      latitude = 0.0
      longitude = 0.0
      api_name = nil

      @@api_list.each do |api|
        if api.counter.increment
          latitude, longitude = api.locate(place_name)
          api_name = api.symbol
          if not (latitude == 0.0 and longitude == 0.0)
            p api.symbol
            api.dump
          end
        end
        break if not (latitude == 0.0 and longitude == 0.0)
      end

      return latitude, longitude, api_name
    end
  end
end


if __FILE__ == $0

  require "version"

  puts "GeocoderSimplified v#{GeocoderSimplified::VERSION} test:\n"

  [
    "50 W Liberty, Reno",
    "New York Metro, NY",
    "San Francisco, CA",
    "Reno, NV, USA",
    "Peoria",
    "Madrid, Spain",
    "London, England"
  ].each do |place_name|
    latitude, longitude, api_name = GeocoderSimplified.locate(place_name)
    puts "% 35s: (%0.8f, %0.8f) via '%s'" % [place_name, latitude, longitude, api_name]
  end

  p GeocoderSimplified.get_counts

end




























