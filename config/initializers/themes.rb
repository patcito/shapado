AVAILABLE_THEMES = []
Dir.foreach(RAILS_ROOT+"/app/stylesheets/themes") do |entry|
  AVAILABLE_THEMES << entry if entry !~ /^\./
end
