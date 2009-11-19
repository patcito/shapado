class Logo < ImageUpload
  key :group_id, ObjectId
  belongs_to :group

  def default_path
    @default_path ||= RAILS_ROOT+"/public/images/default_logo.png"
  end
end
