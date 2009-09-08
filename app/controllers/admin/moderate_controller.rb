class Admin::ModerateController < ApplicationController
  before_filter :login_required
  before_filter :moderator_required
  def index
    @subtab = params.fetch(:tab, "all")

    if @subtab == "all" || @subtab == "questions"
      @questions = Question.paginate(:per_page => 25,
                                     :order => "flags_count desc",
                                     :conditions => {"flags_count" => {"$gt" => 0}},
                                     :page => params[:questions_page] || 1)
    end
    if @subtab == "all" || @subtab == "answers"
      @answers = Answer.paginate(:per_page => 25,
                                 :order => "flags_count desc",
                                 :conditions => {"flags_count" => {"$gt" => 0}},
                                 :page => params[:answers_page] || 1 )
    end
  end

  def moderator_required
    unless current_user.moderator?
      flash[:error] = t("views.layout.permission_denied")
      redirect_to root_path
    end
  end

end
