
file = File.join(RAILS_ROOT, "data", "GeoLiteCity.dat")

if File.exist?(file)
  Localize = GeoIP.new(file)
else
  puts "Missing GeoIP data. Please run '#{RAILS_ROOT}/script/update_geoip'"
end


