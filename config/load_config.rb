require 'ostruct'

config_file = "/etc/shapado.yml"
if !File.exist?(config_file)
  config_file = RAILS_ROOT+"/config/shapado.yml"
end

if !File.exist?(config_file)
  raise StandardError,  "Config file was not found"
end

options = YAML.load_file(config_file)
if !options[RAILS_ENV]
  raise "'#{RAILS_ENV}' was not found in #{config_file}"
end

AppConfig = OpenStruct.new(options[RAILS_ENV])

# check config
begin
  known_options = YAML.load_file(RAILS_ROOT+"/config/shapado.sample.yml")[RAILS_ENV]
  if known_options
    known_options.each do |k, v|
      if AppConfig.send(k).nil?
        $stderr.puts "Warning: missing config option: '#{k}'"
      end
    end
  end
end
