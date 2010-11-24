module I18nActionMailer

  def self.included(base)
    base.send :include, I18nActionMailer::InstanceMethods
    base.send :alias_method_chain, :render_message, :i18n
    base.helper_method :locale, :l, :localize
    base.helper do
      def translate(key, options = {})
        I18n.translate(scope_key_by_partial(key), options.merge!(:raise => true, :locale => self.locale))
      end
      alias_method :t, :translate

      private
        def scope_key_by_partial(key)
          if key.to_s.first == "."
            if @_virtual_path
              @_virtual_path.gsub(%r{/_?}, ".") + key.to_s
            else
              raise "Cannot use t(#{key.inspect}) shortcut because path is not available"
            end
          else
            key
          end
        end
    end
  end

  module InstanceMethods
    def translate(key, options = {})
      I18n.translate(scope_key_by_partial(key), options.merge(:raise => true, :locale => self.locale))
    end
    alias_method :t, :translate

    def localize(key, options = {})
      I18n.localize(key, options.merge(:locale => self.locale))
    end
    alias_method :l, :localize

    def locale
      @locale
    end

    def set_locale(locale)
      @locale = locale
    end

    def render_message_with_i18n(method_name, body)
      method_name = "#{method_name}_#{locale}" if locale and !Dir["#{template_path}/#{method_name}_#{locale}*"].empty?
      render_message_without_i18n(method_name, body)
    end
    
    private
      def scope_key_by_partial(key)
        if key.to_s.first == "."   
          mailer_scope = self.class.mailer_name.gsub('/', '.')
          mailer_scope + "." + action_name + key.to_s
        else
          key
        end
      end      
  end

end

ActionMailer::Base.send(:include, I18nActionMailer)
