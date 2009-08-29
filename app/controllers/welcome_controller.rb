class WelcomeController < ApplicationController
  def index
    order = "updated_at desc"
    if params[:tab] == "votes"
      order = "votes_average desc"
    end
    if params[:tab] == "hot"
      order = "answers_count desc"
    end

    @questions = Question.paginate(:per_page => 25,
                                   :page => params[:page] || 1,
                                   :limit => 20,
                                   :order => order,
                                   :conditions => scoped_conditions({:answered => false}))
  end

  def search
    @questions = Question.search(params[:q], :per_page => 25, :page => params[:page] || 1)
    @answers = Answer.search(params[:q], :per_page => 25, :page => params[:page] || 1)
  end
end

