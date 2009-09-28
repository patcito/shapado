class WelcomeController < ApplicationController
  before_filter :categories_required
  def index
    @active_subtab = params.fetch(:tab, "active")

    order = "activity_at desc"
    case @active_subtab
      when "active"
        order = "activity_at desc"
      when "hot"
        order = "hotness desc"
    end

    @langs_conds = scoped_conditions[:language][:$in]
    add_feeds_url(url_for(:format => "atom", :languages => @langs_conds), t("views.feeds.questions"))

    @questions = Question.paginate(:per_page => 25,
                                   :page => params[:page] || 1,
                                   :limit => 20,
                                   :order => order,
                                   :conditions => scoped_conditions({:answered => false, :banned => false}))
  end

  def search
    @questions = Question.search(params[:q], :per_page => 25, :page => params[:page] || 1)
    @answers = Answer.search(params[:q], :per_page => 25, :page => params[:page] || 1)
  end

  def facts
  end
end

