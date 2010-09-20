class MembershipList < Hash
  def self.to_mongo(value)
    result = {}
    value.each do |k, v|
      if v.kind_of?(Membership)
        result[k] = v.attributes
      else
        result[k] = v
      end
    end

    result
  end

  def self.from_mongo(value)
    return value if value.kind_of?(self)

    result = MembershipList.new
    (value||{}).each do |k, v|
      result[k] = v.kind_of?(Membership) ? v : Membership.new(v)
    end

    result
  end

  def groups(options = {})
    Group.all(options.merge(:_id => self.keys))
  end
end
