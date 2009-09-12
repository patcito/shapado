class WelcomeController < ApplicationController
  def index
    @active_subtab = params.fetch(:tab, "active")

    order = "activity_at desc"
    case @active_subtab
      when "active"
        order = "activity_at desc"
      when "hot"
        order = "hotness desc"
    end


    add_feeds_url(url_for(:format => "atom"), t("views.feeds.questions"))

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
end

