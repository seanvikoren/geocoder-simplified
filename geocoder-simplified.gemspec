# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "geocoder-simplified/version"

Gem::Specification.new do |s|
  s.name        = "geocoder-simplified"
  s.version     = GeocoderSimplified::VERSION
  s.authors     = ["Sean Vikoren"]
  s.email       = ["sean@vikoren.com"]
  s.homepage    = "https://github.com/seanvikoren/geocoder-simplified"
  s.summary     = %q{geocoder-simplified will get lat and long for an address or place name.}
  s.description = %q{The geocoder-simplified gem is intended to offer a no-frills wrapper on the geocoder gem.}

  s.rubyforge_project = "geocoder-simplified"

  s.files         = Dir.glob("lib/**/*.rb")
  #s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # dependencies
  #s.add_development_dependency "rake-compiler"
  s.add_runtime_dependency "geocoder"
  s.add_runtime_dependency "redis-expiring_counter", "~> 1.0.0.0"
end
