require 'bundler/gem_tasks'
#require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

#require 'rake/extensiontask'
require 'rake'

GEM_NAME = 'geocoder-simplified'

spec = Gem::Specification.new do |s|
  s.name = GEM_NAME
  s.platform = Gem::Platform::RUBY
end

# add your default gem packing task
Rake::GemPackageTask.new(spec) do |pkg|
end



