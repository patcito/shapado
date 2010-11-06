if RUBY_PLATFORM !~ /mswin|mingw/
  path = Rails.root.to_s+"/public/javascripts/jsMath"
  if !File.exist?(path+"/fonts")
    puts ">> Installing jsmath fonts..."
    system "tar xjf '#{Rails.root.to_s+"/data/fonts.tar.bz2"}' -C '#{path}'"
  end
end
