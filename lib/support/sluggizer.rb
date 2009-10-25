module Support
  module Sluggizer
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
        extend Finder

        key :slug, String
        ensure_index :slug

        before_validation_on_create :generate_slug
      end
    end

     def to_param
       if self.slug.blank?
         self.id
       else
         self.slug
       end
     end

    protected
    def generate_slug
      if self.slug.blank?
        key = UUIDTools::UUID.random_create.hexdigest[0,4] #optimize
        self.slug = key+"-"+self[self.class.slug_key].to_s.gsub(/[^A-Za-z0-9\s\-]/, "")[0,20].strip.gsub(/\s+/, "-").downcase
      end
    end

    module ClassMethods
      def slug_key(key = :name)
        @slug_key ||= key
      end
    end

    module Finder
      def by_slug(id)
        self.find_by_slug(id) || self.find_by_id(id)
      end
      alias :find_by_slug_or_id :by_slug
    end
  end
end

MongoMapper::Associations::Proxy.send(:include, Support::Sluggizer::Finder)

