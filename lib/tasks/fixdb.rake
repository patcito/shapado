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


  def migrate_file(group, key)
    puts ">> Migrating #{group.name}##{key}"

    cname = Group.collection_name

    files = Group.database["#{cname}.files"]
    chunks = Group.database["#{cname}.chunks"]

    fname = group["_#{key}"]
    return if fname.blank?

    begin
      n = Mongo::GridIO.new(files, chunks, nil, "r", :query => {:filename => fname})

      v = n.read

      puts "DATA: #{v[0,100]}"

      if(v.empty?)
        data = StringIO.new(v)
        group.put_file(key, data)
      end
    rescue => e
      puts "ERROR: #{e}"
      return
    end

    files.remove(:_id => fname)
    chunks.remove(:_id => fname)
  end

  desc "logos"
  task :logos => [:environment] do
    cname = Group.collection_name

    Group.find_each do |group|
      migrate_file(group, "logo")
      migrate_file(group, "custom_css")
      migrate_file(group, "custom_favicon")

      group.save(:validate => false)
    end

    Group.database.drop_collection(cname+".files")
    Group.database.drop_collection(cname+".chunks")

    Group.find_each do |group|
      print ">>> "
      puts group.name
      if group.has_logo?
        puts group.logo.mime_type
      end

      if group.has_custom_css?
        puts group.custom_css.mime_type
      end

      if group.has_custom_favicon?
        puts group.custom_favicon.mime_type
      end
    end
  end
end

