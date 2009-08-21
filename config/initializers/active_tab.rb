module ActiveTab                                                                      
  def self.included(base)                                                               
    base.extend(ClassMethods)                                                           
  end                                                                                   

  module ClassMethods
    unloadable

    def tabs(tabs)
      tabs.symbolize_keys!

      before_filter :set_active_tab

      private
      define_method(:set_active_tab) do
        @active_tab = tabs[params[:action].to_sym]
        @active_tab = tabs[:default] if tabs[:default] && @active_tab.nil?
        @action_tab = 'default_tab' if @active_tab.nil?
        @active_tab
      end
    end
  end
end

ActionController::Base.class_eval do
  include ActiveTab               
end
