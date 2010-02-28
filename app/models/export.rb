class Export
  def initialize(group)
    @group = group
  end

  def export_model(model, io, opts = {})
    selector = opts.delete(:selector) || {:group_id => @group.id}

    model.find_each(selector) do |object|
      io.write object.to_json({:except => [:_keywords]}.merge(opts)) + "\n"
    end
  end

  def to_file(model, opts = {})
    file = File.open("#{model.to_s.tableize}.json", "w")
    export_model(model, file, opts)
    file.close
  end
end
