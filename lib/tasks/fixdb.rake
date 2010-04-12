desc "Fix all"
task :fixall => [:environment, "fixdb:files", "fixdb:orphan_answers"] do
end

namespace :fixdb do
  desc "files"
  task :files => [:environment] do
    Group.upgrade_file_keys("logo", "custom_css", "custom_favicon")

    puts " -------------------------- "
    Group.find_each do |group|
      puts ">>> #{group.name}"
      if group.has_logo?
        puts group.logo.mime_type rescue nil
      end

      if group.has_custom_css?
        puts group.custom_css.mime_type rescue nil
      end

      if group.has_custom_favicon?
        puts group.custom_favicon.mime_type rescue nil
      end
    end
  end

  desc "orphan answers"
  task :orphan_answers => [:environment] do
    Question.find_each(:select => [:_id, :group_id]) do |question|
      Answer.set({"question_id" => question.id}, {"group_id" => question.group_id})
    end
  end
end

