The geocoder-simplified gem is intended to offer a no-frills wrapper on the geocoder gem.

Please let me know if you find a way to make this better.

Cheers,
Sean Vikoren
sean@vikoren.com


Here are some clues to making this into a gem:
git init

<make some changes to the gem and test that it works>
<update the version>
git commit -a -m "updated version"
git push
gem build gem_with_extension_example.gemspec
gem push gem_with_extension_example-0.0.2.2.gem

# For local update after changing .gemspec
bundle update

# Gem Building and Installation
gem build geocoder-simplified.gemspec               # build gem
gem install gem_with_extension_example-0.0.0.gem    # install gem
gem list | grep gem_with_extension_example          # verify installation of gem
gem env                                             # locate installation directory

# Publishing a gem
you will need an account on rubygems.org and github.com
to generate your key:
curl -u vikoren https://rubygems.org/api/v1/api_key.yaml > ~/.gem/credentials

# Local publish
gem 'my_engine', :git => 'http://myserver.com/git/my_engine'


There were many sources used to get this working, but here are a couple:
# Following the 'bundle gem' method
http://railscasts.com/episodes/245-new-gem-with-bundler

# C Extension
http://ruby-doc.org/docs/ProgrammingRuby/html/ext_ruby.html
http://www.eqqon.com/index.php/Ruby_C_Extension_API_Documentation_%28Ruby_1.8%29

