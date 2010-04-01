desc "Fix all"
task :fixall => [:environment, "fixdb:devise"] do
end

namespace :fixdb do
  desc "migrate to devise"
  task :devise => [:environment] do
    User.find_each do |user|
      if user["crypted_password"]
        atts = user.attributes
        atts["encrypted_password"] = atts.delete("crypted_password")
        atts["password_salt"] = atts.delete("salt")
        user.collection.save(atts)
      end
    end
  end
end

