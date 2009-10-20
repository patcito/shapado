class Admin::ModerateController < ApplicationController
  before_filter :login_required
  before_filter :moderator_required

  def index
    @subtab = params.fetch(:tab, "all")

    if @subtab == "all" || @subtab == "questions"
      @questions = Question.paginate(:per_page => 25,
                                     :order => "flags_count desc",
                                     :conditions => {"flags_count" => {"$gt" => 0},
                                                     "banned" => false},
                                     :page => params[:questions_page] || 1)
    end

    if @subtab == "all" || @subtab == "answers"
      @answers = Answer.paginate(:per_page => 25,
                                 :order => "flags_count desc",
                                 :conditions => {"flags_count" => {"$gt" => 0},
                                                 "banned" => false},
                                 :page => params[:answers_page] || 1 )
    end
  end

  def ban
    Question.ban(params[:question_ids] || [])
    Answer.ban(params[:answer_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

end

