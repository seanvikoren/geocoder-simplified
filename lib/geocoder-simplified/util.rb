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
    def get_16bit_hash_id(s)
      "%04x" % s.bytes.each_with_index.map{|c,i| c << ((i & 1) * 8)}.inject(0xFFFF){|hash, n| hash ^ n}
    end
    def capture_stderr
      previous_stderr, $stderr = $stderr, StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = previous_stderr
    end
  end
end
