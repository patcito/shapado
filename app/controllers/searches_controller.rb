class SearchesController < ApplicationController
  def index
    options = {:per_page => 25, :page => params[:page] || 1}
    unless params[:q].blank?
      pharse = params[:q].downcase
      @search_tags = pharse.scan(/\[(\w+)\]/).flatten
      @search_text = pharse.gsub(/\[(\w+)\]/, "")
      options[:tags] = {:$all => @search_tags} unless @search_tags.empty?
      options[:group_id] = current_group.id
      options[:order] = params[:sort_by] if params[:sort_by]
      options[:banned] = false

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

    respond_to do |format|
      format.html
      format.js do
        render :json => {:html => render_to_string(:partial => "questions/question",
                                                   :collection  => @questions)}.to_json
      end
      format.json { render :json => @questions.to_json(:except => %w[_keywords slugs watchers]) }
    end
  end
end
