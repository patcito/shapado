module JudgeActions
  module Users
    def on_update_user(payload)
      user = User.find!(payload.shift)
      group = Group.find!(payload.shift)

      if !user.birthday.blank? && !user.website.blank? && !user.bio.blank? && !user.name.blank?
        create_badge(user, group, :token => "autobiographer", :unique => true)
      end
    end
  end
end
