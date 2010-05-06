class Admin::ModerateController < ApplicationController
  before_filter :login_required
  before_filter :moderator_required

  def index
    @active_subtab = params.fetch(:tab, "retag")

    options = {:banned => false,
               :group_id => current_group.id,
               :per_page => params[:per_page] || 25,
               :page => params[:questions_page] || 1}


    case @active_subtab
      when "flagged_questions"
        @questions = Question.paginate(options.merge(:order => "flags_count desc", :flags_count.gt => 0))
      when "flagged_answers"
        @answers = Answer.paginate(options.merge(:order => "flags_count desc", :flags_count.gt => 0))
      when "banned"
        @banned = Question.paginate(options.merge(:banned => true))
      when "retag"
        @questions = Question.paginate(options.merge(:tags => {:$size => 0}))
    end
  end

  def ban
    Question.ban(params[:question_ids] || [])
    Answer.ban(params[:answer_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

  def unban
    Question.unban(params[:question_ids] || [])

    respond_to do |format|
      format.html{redirect_to :action => "index"}
    end
  end

end

