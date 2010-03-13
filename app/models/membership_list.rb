class MembershipList < Hash
  def self.to_mongo(value)
    return value if kind_of?(self)

    result = {}
    value.each do |k, v|
      result[k] = v.to_mongo
    end

    result
  end

  def self.from_mongo(value)
    return value if kind_of?(self)

    result = MembershipList.new
    (value||{}).each do |k, v|
      result[k] = v.kind_of?(Membership) ? v : Membership.new(v)
    end

    result
  end
end
