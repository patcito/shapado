class AnswersController < ApplicationController
  before_filter :login_required, :except => [:show, :create]
  before_filter :check_permissions, :only => [:destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :revert]

  helper :votes

  def history
    @answer = Answer.find(params[:id])
    @question = @answer.question

    respond_to do |format|
      format.html
      format.json { render :json => @answer.versions.to_json }
    end
  end

  def diff
    @answer = Answer.find(params[:id])
    @question = @answer.question
    @prev = params[:prev]
    @curr = params[:curr]
    if @prev.blank? || @curr.blank? || @prev == @curr
      flash[:error] = "please, select two versions"
      render :history
    else
      if @prev
        @prev = (@prev == "current" ? :current : @prev.to_i)
      end

      if @curr
        @curr = (@curr == "current" ? :current : @curr.to_i)
      end
    end
  end

  def revert
    @question = @answer.question
    @answer.load_version(params[:version].to_i)

    respond_to do |format|
      format.html
    end
  end

  def show
    @answer = Answer.find(params[:id])
    raise PageNotFound if @answer.nil?
    @question = @answer.question
    respond_to do |format|
      format.html
      format.json  { render :json => @answer.to_json }
    end
  end

  def create
    @answer = Answer.new
    @answer.safe_update(%w[body wiki anonymous], params[:answer])
    @question = Question.find_by_slug_or_id(params[:question_id])
    @answer.question = @question
    @answer.group_id = @question.group_id

    # workaround, seems like mm default values are broken
    @answer.votes_count = 0
    @answer.votes_average = 0
    @answer.flags_count = 0

    @answer.user = current_user
    if !logged_in?
      if recaptcha_valid? && params[:user]
        @user = User.first(:email => params[:user][:email])
        if @user.present?
          if !@user.anonymous
            flash[:notice] = "The user is already registered, please log in"
            return create_draft!
          else
            @answer.user = @user
          end
        else
          @user = User.new(:anonymous => true, :login => "Anonymous")
          @user.safe_update(%w[name email website], params[:user])
          @user.login = @user.name if @user.name.present?
          @user.save!
          @answer.user = @user
        end
      elsif !AppConfig.recaptcha["activate"]
        return create_draft!
      end
    end

    respond_to do |format|
      if (logged_in? || (recaptcha_valid? && @answer.user.valid?)) && @answer.save
        after_create_answer

        flash[:notice] = t(:flash_notice, :scope => "answers.create")
        format.html{redirect_to question_path(@question)}
        format.json { render :json => @answer.to_json(:except => %w[_keywords]) }
        format.js do
          render(:json => {:success => true, :message => flash[:notice],
            :html => render_to_string(:partial => "questions/answer",
                                      :object => @answer,
                                      :locals => {:question => @question})}.to_json)
        end
      else
        @answer.errors.add(:captcha, "is invalid") if !logged_in? && !recaptcha_valid?

        errors = @answer.errors
        errors.merge!(@answer.user.errors) if @answer.user.anonymous && !@answer.user.valid?
        puts errors.full_messages

        flash.now[:error] = errors.full_messages
        format.html{redirect_to question_path(@question)}
        format.json { render :json => errors, :status => :unprocessable_entity }
        format.js {render :json => {:success => false, :message => flash.now[:error] }.to_json }
      end
    end
  end

  def edit
    @question = @answer.question
  end

  def update
    respond_to do |format|
      @question = @answer.question
      @answer.safe_update(%w[body wiki version_message anonymous], params[:answer])
      @answer.updated_by = current_user

      if @answer.valid? && @answer.save
        sweep_question(@question)

        Question.update_last_target(@question.id, @answer)

        flash[:notice] = t(:flash_notice, :scope => "answers.update")

        Magent.push("actors.judge", :on_update_answer, @answer.id)
        format.html { redirect_to(question_path(@answer.question)) }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @answer.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @question = @answer.question
    if @answer.user_id == current_user.id
      @answer.user.update_reputation(:delete_answer, current_group)
    end
    @answer.destroy
    @question.answer_removed!
    sweep_question(@question)

    Magent.push("actors.judge", :on_destroy_answer, current_user.id, @answer.attributes)

    respond_to do |format|
      format.html { redirect_to(question_path(@question)) }
      format.json { head :ok }
    end
  end

  protected
  def check_permissions
    @answer = Answer.find(params[:id])
    if !@answer.nil?
      unless (current_user.can_modify?(@answer) || current_user.mod_of?(@answer.group))
        flash[:error] = t("global.permission_denied")
        redirect_to question_path(@answer.question)
      end
    else
      redirect_to questions_path
    end
  end

  def check_update_permissions
    @answer = Answer.find!(params[:id])

    allow_update = true
    unless @answer.nil?
      if !current_user.can_modify?(@answer)
        if @answer.wiki
          if !current_user.can_edit_wiki_post_on?(@answer.group)
            allow_update = false
            reputation = @question.group.reputation_constrains["edit_wiki_post"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_wiki_post"))
          end
        else
          if !current_user.can_edit_others_posts_on?(@answer.group)
            allow_update = false
            reputation = @answer.group.reputation_constrains["edit_others_posts"]
            flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                        :min_reputation => reputation,
                                        :action => I18n.t("users.actions.edit_others_posts"))
          end
        end
        return redirect_to question_path(@answer.question) if !allow_update
      end
    else
      return redirect_to questions_path
    end
  end

  def create_draft!
    draft = Draft.create(:answer => @answer)
    session[:draft] = draft.id
    login_required
  end

  # TODO: use magent to do it
  def after_create_answer
    sweep_question(@question)

    Question.update_last_target(@question.id, @answer)

    @question.answer_added!
    current_group.on_activity(:answer_question)

    unless @answer.anonymous
      @answer.user.stats.add_answer_tags(*@question.tags)
      @answer.user.on_activity(:answer_question, current_group)

      search_opts = {"notification_opts.#{current_group.id}.new_answer" => {:$in => ["1", true]},
                      :_id => {:$ne => @answer.user.id},
                      :select => ["email"]}

      users = User.all(search_opts.merge(:_id => @question.watchers))
      users.push(@question.user) if !@question.user.nil? && @question.user != @answer.user
      followers = @answer.user.followers(:languages => [@question.language], :group_id => current_group.id)

      users ||= []
      followers ||= []
      (users - followers).each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, false)
        end
      end

      followers.each do |u|
        if !u.email.blank? && u.notification_opts.new_answer
          Notifier.deliver_new_answer(u, current_group, @answer, true)
        end
      end
    end
  end
end
