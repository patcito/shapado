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

    def subtabs(subtabs)
      subtabs.symbolize_keys!

      before_filter :set_active_subtab

      define_method(:current_order) do
        @current_order
      end
      helper_method :current_order

      private
      define_method(:set_active_subtab) do
        @subtabs = subtabs[params[:action].to_sym]
        if !@subtabs.blank?
          @active_subtab = params.fetch(:sort, @subtabs.first.first.to_s)
          @subtabs.each do |st|
            if st.first.to_s == @active_subtab
              @current_order = st.last
              break
            end
          end
          @current_order ||= @subtabs.first.last
        end
      end
    end
  end
end

ActionController::Base.class_eval do
  include ActiveTab
end
