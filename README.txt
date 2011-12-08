The geocoder-simplified gem is intended to offer a no-frills wrapper on the geocoder gem.
Please let me know if you find a way to make this better.

Cheers,
Sean Vikoren
sean@vikoren.com


Example Usage:

require "geocoder-simplified"

place_name = "Reno, NV, USA"
latitude, longitude, api_name = GeocoderSimplified.locate(place_name)
puts "% 35s: (%0.8f, %0.8f) via '%s'" % [place_name, latitude, longitude, api_name]

# => Reno, NV, USA: (39.52963300, -119.81380300) via 'geocoder_ca'