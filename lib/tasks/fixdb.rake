desc "Fix all"
task :fixall => [:environment, "fixdb:custom_html", "fixdb:reindex"] do
end

namespace :fixdb do
  desc "move custom html keys to embedded doc"
  task :custom_html => :environment do
    $stderr.puts "Updating #{Group.count} groups..."

    Group.find_each do |group|
      group.set({"custom_html.question_prompt" => group[:_question_prompt],
                 "custom_html.question_help" => group[:_question_help],
                 "custom_html.head" => group[:_head],
                 "custom_html.footer" => group[:footer],
                 "custom_html.head_tag" => group[:head_tag]})
    end

    modifiers = {}
    %w[_question_prompt _question_help _head footer head_tag].each do |key|
      modifiers[key] = 1
    end
    Group.collection.update({}, {:$unset => modifiers}, :multi => true)
  end

  task "reindex groups"
  task :reindex => :environment do
    $stderr.puts "Reindexing #{Group.count} groups..."
    Group.find_each do |group|
      group._keywords = []
      group.save(:validate => false)
    end
  end
end

