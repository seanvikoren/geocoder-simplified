
if __FILE__ == $0 # if this file is being executed, run this code

  require "redis"

  $:.push File.expand_path("../../lib/geocoder-simplified", __FILE__) # not a general solution
  require "version"
  require "redis_table"

  puts "#{File.basename($0)} v#{GeocoderSimplified::VERSION}"
  puts

  @@redis_db_0 = Redis.new # 16 databases available, this selects 0

  RedisTable.flush_redis

  12.times do |i|
    key = "%02d" % i
    @@redis_db_0.set(key, 'o')
    @@redis_db_0.expire(key, 3)
    puts "Added '#{key}'"
    sleep 0.25
  end

  5.times do
    puts "----------------------------------------------------------------------------"
    puts Time.now.inspect
    RedisTable.dump_database
    puts
    sleep 1
  end

end



























