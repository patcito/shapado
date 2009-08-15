class WelcomeController < ApplicationController
  def index
    @questions = Question.paginate(:per_page => 25,
                                   :page => params[:page] || 1,
                                   :limit => 20,
                                   :order => "created_at desc",
                                   :conditions => {:answered => false})
  end

  def search
    @questions = Question.search(params[:q])
  end
end
