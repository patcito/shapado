class WelcomeController < ApplicationController
  def index
    @questions = Question.paginate(:per_page => 25,
                                   :page => params[:page] || 1,
                                   :limit => 20,
                                   :order => "updated_at desc",
                                   :conditions => scoped_conditions({:answered => false}))
  end

  def search
    @questions = Question.search(params[:q], :per_page => 25, :page => params[:page] || 1)
    @answers = Answer.search(params[:q], :per_page => 25, :page => params[:page] || 1)
  end
end

