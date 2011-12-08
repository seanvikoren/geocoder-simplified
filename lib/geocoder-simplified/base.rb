# encoding: utf-8

# holy grail of redis info:
# http://dev.mensfeld.pl/2011/11/using-redis-as-a-temporary-cache-for-data-shared-by-multiple-independent-processes/

# monkeypatch ruby from the rails underscore addition to String

class GeocoderSimplified
  $:.push File.expand_path("..", __FILE__)

  require 'geocoder'
  require 'redis'
  require 'util'
  require 'redis-expiring_counter'

  POSTFIX = "Geocode"
  UNLIMITED_CALLS = Util::MAX_INT32

  class Configuration # Future Development Stub
    GOOGLE_API_KEY = ""
    YAHOO_API_KEY = ""
  end
  class GeocoderApi# < RedisTable
    attr_reader :name, :key, :max_calls_per_day, :symbol, :counter
    def initialize(name, key, max_calls_per_day)
      @name = name + POSTFIX
      @key = key
      @max_calls_per_day = max_calls_per_day
      @symbol = name.underscore.to_sym
      @counter = RedisExpiringCounter.new(@name, Util::SECONDS_PER_DAY, @max_calls_per_day)
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

      Geocoder::Configuration.lookup = @symbol # set the geocoder to use this api

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
  end

  class << self
    # Attach the default goecoding apis, _in order_.  The first added will be the first tried.
    @@api_list = []
    @@api_list << GeocoderApi.new("GeocoderCa", "", UNLIMITED_CALLS)
    @@api_list << GeocoderApi.new("Google", Configuration::GOOGLE_API_KEY, 2500)
    @@api_list << GeocoderApi.new("Yahoo", Configuration::YAHOO_API_KEY, 50000)
    #@@api_list.each{|api| puts "#{api.count}:#{api.symbol}"}

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
          if not (latitude == 0.0 and longitude == 0.0)
            api_name = api.symbol
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

  puts "GeocoderSimplified v#{GeocoderSimplified::VERSION} test:\n\n"

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

  puts
  p GeocoderSimplified.get_counts

end




























