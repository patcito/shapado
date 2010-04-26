desc "Fix all"
task :fixall => [:environment, "setup:create_pages", "setup:reindex"] do
end

namespace :fixdb do
end

