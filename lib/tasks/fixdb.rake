desc "Fix all"
task :fixall => [:environment, "fixdb:pages"] do
end

namespace :fixdb do
  task :pages => :environment do
    Group.all(:language.nin => [nil, ""]).each do |g|
      g.pages.destroy_all(:language.ne => g.language)
    end
  end
end

