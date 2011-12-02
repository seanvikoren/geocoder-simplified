

=begin

WARNING: This class will wipe one Redis database per counter

Note:
  If you need more counters, this can easily be extended to use multiple databases
  through @@db_config.

  A note on speed: A key search based method is about ten times slower than using dbsize.

  :host       remote ip, default is 127.0.0.1
  :port       default is 6379
  :password   if you require a password on connection
  :db         default is 0
  :timeoeut   default is 5 seconds
  :logger     to log activity as database it works

Persistance:
  The counters will live on across sessions unless explicitly deleted.

Speed Improment Note:
  Let time_frame be the span of time winin which we are limiting some action (say one day for example).
  Let time_chunk be a timespan (5 minutes for instance).
  Let each time_chunk be a counter with an expiration.
  Let chunk_count be the number of time_chunks that will fit entirely within time frame.
  v = sum(time_chunk[i].count)

  We note that this method can work within an existing DB without issue.
=end

class RedisExpiringCounter
  $:.push File.expand_path("..", __FILE__)

  require 'redis'
  require 'configuration'

  attr_reader :db_index

  def initialize(expiration_in_seconds, max_count, existing_db_id = nil)
    pre_existing = (not existing_db_id.nil?)
    @expiration_in_seconds = expiration_in_seconds
    @max_count = max_count

    @db_index = pre_existing ? existing_db_id.to_i : get_next_index
    @id_key = @@id_key_list[@db_index]
    @@db_0.incr(@id_key)
    @db = Redis.new({:db => @db_index, :host => Configuration::HOST, :port => Configuration::DB_PORT})

    @db.flushdb unless pre_existing
    print pre_existing ? "Old " : "New "
    puts "Counter (#{@@id_key_list[@db_index]} = #{@db.dbsize})"
  end

  def get_next_index
    print "get_next_index: "
    next_index = nil
    @@db_range.each do |i|
      key = @@id_key_list[i]
      if not @@db_0.exists(key)
        next_index = i
        break
      end
    end
    raise "Exceeded maximum number of expiring counters.  Modify class (#{self.class.to_s}) for more.  And don't forget to call delete when a counter is no longer in use." if next_index.nil?
    puts next_index
    next_index
  end

  def increment
    if @db.dbsize < @max_count
      key = @@db_0.incr(@id_key)
      @db.setex(key, @expiration_in_seconds, '1')
      true
    else
      false
    end
  end

  def count
    @db.dbsize
  end

  def delete
    puts "delete '#{@id_key}'"
    @@db_0.del(@id_key)
    @db.flushdb
  end

  def dump
    puts "database #{@db_index}:"
    keys = @db.keys
    if keys.size > 0
      values = @db.mget(*keys)
      list = Hash[keys.zip(values)]
      list.each{|k, v| puts "%s = %s" % [k, v]}
    end
  end

  class << self
    @@db_0 = Redis.new({:db => 0, :host => Configuration::HOST, :port => Configuration::DB_PORT})
    @@db_range = (Configuration::FIRST_COUTER_DB_DB..Configuration::LAST_COUNTER_DB_ID)
    @@id_key_list = (0..Configuration::LAST_COUNTER_DB_ID).each.map{|i| "expiring:counter:#{i}"}

    def exists(db_id)
      @@db_0.exists(@@id_key_list[db_id])
    end
    def delete(db_id)
      @@db_0.del(@@id_key_list[db_id])
    end
    def delete_all_counters
      @@db_range.each do |i|
        if @@db_0.exists(@@id_key_list[i])
          @@db_0.del(@@id_key_list[i])
        end
      end
    end
  end
end








if __FILE__ == $0 # if this file is being executed directly, run this code

  def dump_database(db)
    puts "-" * 76
    puts "database dump:"
    keys = db.keys
    if keys.size > 0
      values = db.mget(*keys)
      list = Hash[keys.zip(values)]
      list.each{|k, v| puts "%s = %s" % [k, v]}
    end
  end

  def float_with_commas(n, decimal_places)
    whole = Integer(n)
    fraction = n - whole
    decimal_format = "%%.%df" % decimal_places
    whole.to_s.reverse.gsub(/...(?=.)/,'\&,').reverse << (decimal_format % fraction)[1..-1]
  end

  duration_of_limit_in_seconds = 300
  google_max_calls_per_day = 4000
  yahoo_max_calls_per_day = 4000

  #Redis.new.flushall
  #require 'pry'

  puts "Make google counter..."
  google_counter = RedisExpiringCounter.new(duration_of_limit_in_seconds, google_max_calls_per_day, 1)

  puts "Make yahoo counter..."
  yahoo_counter = RedisExpiringCounter.new(duration_of_limit_in_seconds, yahoo_max_calls_per_day, 2)

  p google_counter.inspect
  p yahoo_counter.inspect

  1000.times do
    if google_counter.increment
      # call google api
    end
    sleep 0.0015
  end

  100.times do
    if yahoo_counter.increment
      # call yahoo api
    end
    sleep 0.015
  end

  5.times do
    puts
    puts "g count = #{google_counter.count}"
    puts "y count = #{yahoo_counter.count}"
    sleep 0.9
  end

  puts
  p google_counter.inspect
  p yahoo_counter.inspect
  puts

  # free the counters
  puts "Remove google counter..."
  google_counter.delete
  #yahoo_counter.delete

  require "benchmark"

  ITERATION_COUNT = 50000

  dump_database(Redis.new); puts
  counter = RedisExpiringCounter.new(23, ITERATION_COUNT)
  dump_database(Redis.new); puts

  p counter.inspect
  puts "#{ITERATION_COUNT} increments with a check on each:"

  t = nil
  Benchmark.bm do |outer_pass|
    t = outer_pass.report("count with expiration: ") do
      ITERATION_COUNT.times do
        if counter.increment
          # call api
        end
      end
    end
  end

  ms_per_call = ((t.real * 1000.0) / ITERATION_COUNT)
  calls_per_second = Integer(1000.0 / ms_per_call)
  puts
  p counter.inspect
  #puts "#{ms_per_call}ms per call."
  puts "#{calls_per_second} calls per second."

end






