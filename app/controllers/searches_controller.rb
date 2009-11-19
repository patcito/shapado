class SearchesController < ApplicationController
  def index
    options = {:per_page => 25, :page => params[:page] || 1}
    unless params[:q].blank?
      pharse = params[:q].downcase
      tags = pharse.scan(/\[(\w+)\]/).flatten
      text = pharse.gsub(/\[(\w+)\]/, "")
      unless tags.empty?
        options[:tags] = {:$all => tags}
        @current_tags = tags
      end

      if !text.blank?
        q = text.split.map do |k|
          Regexp.escape(k)
        end.join("|")
        @query_regexp = /(#{q})/i
        @questions = Question.filter(text, options)
      else
        @questions = Question.paginate(options)
      end
    else
      @questions = Question.paginate(options)
    end
  end
end
