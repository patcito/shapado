module Support
module Versioneable
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      attr_accessor :rolling_back
      many :versions
      before_save :save_version, :if => Proc.new { |d| !d.rolling_back }
    end
  end

  module InstanceMethods
    def rollback!(pos = nil)
      pos = self.versions.count-1 if pos.nil?
      version = self.versions[pos]

      if version
        version.data.each do |key, value|
          self.send("#{key}=", value.first)
        end
        self.updated_by_id = version.user_id
        self.updated_at = version.updated_at
      end

      @rolling_back = true
      save!
    end
  end

  module ClassMethods
    def versioneable_keys(*keys)
      define_method(:save_version) do
        data = {}
        keys.each do |key|
          if change = changes[key.to_s]
            data[key.to_s] = change
          end
        end

        if !self.new? && !data.empty? && self.updated_by_id
          e = Time.now
          self.versions << Version.new({'data' => data,
                                        'user_id' => (self.updated_by_id_was || self.updated_by_id),
                                        'date' => e.kind_of?(ActiveSupport::TimeWithZone) ? e.utc : e })
        end
      end
    end
  end
end
end

