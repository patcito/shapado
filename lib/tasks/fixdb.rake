desc "Fix all"
task :fixall => [:environment, "fixdb:logo"] do
end

namespace :fixdb do
  desc "Update groups' logos"
  task :logo => :environment do
    $stderr.puts "Updating #{Group.count} groups..."
    MongoMapper.database.collection("image_uploads").find.each do |i|
      g = Group.find(i["group_id"])
      puts "Updating #{g.name}..."

      filename = g.name.gsub("/", "_")+"_logo.png"
      g.logo_ext = 'png'

      if !g.nil? && !i["image"].to_s.blank?
        File.open(filename, "w") do |file|
          file << i["image"].to_s
        end

        File.open(filename, "r") do |file|
          if file.stat.size > 0
            g.logo = file
            g.save
          end
        end
        File.delete(filename)
      end
    end
  end
end
