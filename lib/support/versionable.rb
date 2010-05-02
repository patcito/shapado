module Support
module Versionable
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      attr_accessor :rolling_back
      key :version_message
      many :versions
      before_save :save_version, :if => Proc.new { |d| !d.rolling_back }

      alias_method :assign_versions, :versions=
      define_method(:versions=) do |v|
        return if v.nil?
        assign_versions v
      end
    end
  end

  module InstanceMethods
    def rollback!(pos = nil)
      pos = self.versions.count-1 if pos.nil?
      version = self.versions[pos]

      if version
        version.data.each do |key, value|
          self.send("#{key}=", value)
        end
        self.updated_by_id = version.user_id unless self.updated_by_id_changed?
        self.updated_at = version.date unless self.updated_at_changed?
      end

      @rolling_back = true
      save!
    end

    def load_version(pos = nil)
      pos = self.versions.count-1 if pos.nil?
      version = self.versions[pos]

      if version
        version.data.each do |key, value|
          self.send("#{key}=", value)
        end
      end
    end

    def diff(key, pos1, pos2, format = :html)
      version1 = self.version_at(pos1)
      version2 = self.version_at(pos2)

      Differ.diff_by_word(version1.content(key), version2.content(key)).format_as(format)
    end

    def current_version
      Version.new(:data => self.attributes, :user_id => (self.updated_by_id_was || self.updated_by_id), :date => Time.now)
    end

    def version_at(pos)
      case pos
      when :current
        current_version
      when :first
        self.versions.first
      when :last
        self.versions.last
      else
        self.versions[pos]
      end
    end
  end

  module ClassMethods
    def versionable_keys(*keys)
      define_method(:save_version) do
        data = {}
        message = ""
        keys.each do |key|
          if change = changes[key.to_s]
            data[key.to_s] = change.first
          else
            data[key.to_s] = self[key]
          end
        end

        if message_changes = self.changes["version_message"]
          message = message_changes.first
        else
          version_message = ""
        end

        if !self.new? && !data.empty? && self.updated_by_id
          e = Time.now
          self.versions << Version.new({'data' => data,
                                        'user_id' => (self.updated_by_id_was || self.updated_by_id),
                                        'date' => e.kind_of?(ActiveSupport::TimeWithZone) ? e.utc : e,
                                        'message' => message})
        end
      end

      define_method(:versioned_keys) do
        keys
      end
    end
  end
end
end

