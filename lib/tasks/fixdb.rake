desc "Fix all"
task :fixall => [:environment, "fixdb:files"] do
end

namespace :fixdb do
  def migrate_file(group, key)
    cname = Group.collection_name

    files = Group.database["#{cname}.files"]
    chunks = Group.database["#{cname}.chunks"]

    fname = group["_#{key}"]
    return if fname.blank?

    puts ">> Migrating #{group.name}##{key}"

    begin
      n = Mongo::GridIO.new(files, chunks, fname, "r", :query => {:filename => fname})

      v = n.read

      if !v.empty?
        data = StringIO.new(v)
        group.put_file(key, data)
      else
        puts "There's no data to save. skipping..'"
      end
    rescue => e
      puts "ERROR: #{e}"
      puts e.backtrace.join("\t\n")
      return
    end

    files.remove(:_id => fname)
    chunks.remove(:_id => fname)
  end

  desc "files"
  task :files => [:environment] do
    cname = Group.collection_name

    Group.find_each do |group|
      migrate_file(group, "logo")
      migrate_file(group, "custom_css")
      migrate_file(group, "custom_favicon")

      group.save(:validate => false)
    end

    Group.database.drop_collection(cname+".files")
    Group.database.drop_collection(cname+".chunks")

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
end

