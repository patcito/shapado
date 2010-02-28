class SearchesController < ApplicationController
  def index
    options = {:per_page => 25, :page => params[:page] || 1}
    unless params[:q].blank?
      pharse = params[:q].downcase
      @search_tags = pharse.scan(/\[(\w+)\]/).flatten
      @search_text = pharse.gsub(/\[(\w+)\]/, "")
      options[:tags] = {:$all => @search_tags} unless @search_tags.empty?
      options[:group_id] = current_group.id

      if !@search_text.blank?
        q = @search_text.split.map do |k|
          Regexp.escape(k)
        end.join("|")
        @query_regexp = /(#{q})/i
        @questions = Question.filter(@search_text, options)
      else
        @questions = Question.paginate(options)
      end
    else
      @questions = []
    end
  end
end
