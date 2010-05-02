desc "Fix all"
task :fixall => [:environment] do
end

namespace :fixdb do
  desc "move custom html keys to embedded doc"
  task :custom_html => :environment do
    Group.find_each do |group|
      group.set("custom_html.question_prompt" => group._question_prompt)
      group.set("custom_html.question_help" => group._question_help)
      group.set("custom_html.head" => group._head)
      group.set("custom_html.footer" => group.footer)
      group.set("custom_html.head_tag" => group.head_tag)

      atts = group.attributes
      %[_question_prompt _question_help _head footer head_tag].each do |key|
        atts.delete(key)
      end
      group.collection.save(atts)
    end
  end
end

