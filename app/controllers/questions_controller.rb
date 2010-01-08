class QuestionsController < ApplicationController
  before_filter :login_required, :except => [:new, :index, :show, :tags, :unanswered]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update]
  before_filter :set_active_tag

  tabs :default => :questions, :tags => :tags,
       :unanswered => :unanswered, :new => :ask_question

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc"], [:votes, "votes_count desc"], [:activity, "activity_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_count desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_count desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]
  helper :votes

  # GET /questions
  # GET /questions.xml
  def index
    set_page_title(t("questions.index.title"))
    @questions = Question.paginate({:per_page => 25, :page => params[:page] || 1,
                                   :order => current_order,
                                   :fields => (Question.keys.keys - ["_keywords", "watchers"])}.
                                  merge( scoped_conditions(:banned => false)))

    @langs_conds = scoped_conditions[:language][:$in]

    add_feeds_url(url_for(:format => "atom", :language=>@langs_conds), t("feeds.questions"))
    if params[:tags]
      add_feeds_url(url_for(:format => "atom", :tags => params[:tags], :language=>@langs_conds),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end
    @tag_cloud = Question.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @questions.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  def unanswered
    set_page_title(t("questions.unanswered.title"))

    @active_subtab = "newest" if !logged_in? && @active_subtab == "mytags"

    @tag_cloud = Question.tag_cloud({:group_id => current_group.id}.
                    merge(language_conditions.merge(language_conditions)), 25)

    if @active_subtab != "mytags"
      @questions = Question.paginate({:order => current_order,
                                      :per_page => 25,
                                      :page => params[:page] || 1,
                                      :fields => (Question.keys.keys - ["_keywords", "watchers"])
                                     }.merge(scoped_conditions({:answered => false})))
    else
      login_required
      @current_tags = current_user.preferred_tags_on(current_group)

      conditions = scoped_conditions({:answered => false})
      @questions = Question.paginate({
                                      :per_page => 25,
                                      :page => params[:page] || 1,
                                      :fields => (Question.keys.keys - ["_keywords", "watchers"])
                                     }.merge(conditions))
    end
    render
  end

  def tags
    set_page_title(t("layouts.application.tags"))
    @tag_cloud = Question.tag_cloud({:group_id => current_group.id}.
                    merge(language_conditions.merge(language_conditions)))
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find_by_slug_or_id(params[:id])

    raise PageNotFound  unless @question

    @tag_cloud = Question.tag_cloud(:_id => @question.id)

    options = {:per_page => 25, :page => params[:page] || 1,
               :order => current_order, :banned => false}
    options[:_id] = {:$ne => @question.answer_id} if @question.answer_id
    @answers = @question.answers.paginate(options)

    @answer = Answer.new(params[:answer])
    @question.viewed! if @question.user != current_user && !is_bot?

    set_page_title(@question.title)
    add_feeds_url(url_for(:format => "atom"), t("feeds.question"))

    respond_to do |format|
      format.html # show.html.erb
      format.json  { render :json => @question.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  # GET /questions/new
  # GET /questions/new.xml
  def new
    @question = Question.new(params[:question])

    if !logged_in?
      draft = Draft.create(:question => @question)
      session[:draft] = draft.id
      login_required
    else
      respond_to do |format|
        format.html # new.html.erb
        format.json  { render :json => @question.to_json }
      end
    end
  end

  # GET /questions/1/edit
  def edit
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new
    @question.safe_update(%w[title body language tags], params[:question])
    @question.group = current_group
    @question.user = current_user

    respond_to do |format|
      if @question.save
        current_user.stats.add_question_tags(*@question.tags)

        current_user.on_activity(:ask_question, current_group)
        current_group.on_activity(:ask_question)

        Magent.push("/actors/judge", :on_ask_question, @question.id)

        flash[:notice] = t(:flash_notice, :scope => "questions.create")
        # TODO: move to magent
        users = User.find_experts(@question.tags, [@question.language])
        users.each do |u|
          email = u.email
          if !email.blank?
            Notifier.deliver_give_advice(u, current_group, @question)
          end
        end

        format.html { redirect_to(question_path(current_languages, @question)) }
        format.json  { render :json => @question.to_json, :status => :created, :location => @question }
      else
        format.html { render :action => "new" }
        format.json  { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    respond_to do |format|
      @question.safe_update(%w[title body language tags], params[:question])
      if @question.valid? && @question.save
        flash[:notice] = t(:flash_notice, :scope => "questions.update")
        format.html { redirect_to(question_path(current_languages,@question)) }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.json  { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question.user.update_reputation(:delete_question, current_group)
    @question.destroy

    Magent.push("/actors/judge", :on_destroy_question, @question.user.id)

    respond_to do |format|
      format.html { redirect_to(questions_url) }
      format.json  { head :ok }
    end
  end

  def solve
    @answer = @question.answers.find(params[:answer_id])
    @question.answer = @answer
    @question.answered = true

    respond_to do |format|
      if @question.save
        current_user.on_activity(:close_question, current_group)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution, current_group)
        end

        Magent.push("/actors/judge", :on_question_solved, @question.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "questions.solve")
        format.html { redirect_to question_path(current_languages, @question) }
        format.json  { head :ok }
      else
        format.html { render :action => "show" }
        format.json  { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unsolve
    @answer_id = @question.answer.id
    @answer_owner = @question.answer.user

    @question.answer = nil
    @question.answered = false

    respond_to do |format|
      if @question.save
        flash[:notice] = t(:flash_notice, :scope => "questions.unsolve")
        current_user.on_activity(:reopen_question, current_group)
        if current_user != @answer_owner
          @answer_owner.update_reputation(:answer_unpicked_as_solution, current_group)
        end

        Magent.push("/actors/judge", :on_question_unsolved, @question.id, @answer_id)

        format.html { redirect_to question_path(current_languages, @question) }
        format.json  { head :ok }
      else
        format.html { render :action => "show" }
        format.json  { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  def flag
    @question = Question.find_by_slug_or_id(params[:id])
    @flag = Flag.new
    @flag.flaggeable_type = @question.class.name
    @flag.flaggeable_id = @question.id
    respond_to do |format|
      format.html
      format.json
    end
  end


  def watch
    @question = Question.find_by_slug_or_id(params[:id])
    @question.add_watcher(current_user)
    flash[:notice] = t("questions.watch.success")

    redirect_to question_path(current_languages, @question)
  end

  def unwatch
    @question = Question.find_by_slug_or_id(params[:id])
    @question.remove_watcher(current_user)
    redirect_to question_path(current_languages, @question)
  end

  def move
    @question = Question.find_by_slug_or_id(params[:id])
    render
  end

  def move_to
    @group = Group.find_by_slug_or_id(params[:question][:group])
    @question = Question.find_by_slug_or_id(params[:id])
    if @group
      @question.group = @group
      @question.save
      flash[:notice] = t("questions.move_to.success", :group => @group.name)
      redirect_to question_path(current_languages, @question)
    else
      flash[:error] = t("questions.move_to.group_dont_exists",
                        :group => params[:question][:group])
      render :move
    end
  end

  protected
  def check_permissions
    @question = Question.find_by_slug_or_id(params[:id])

    if @question.nil?
      redirect_to questions_path
    elsif !current_user.can_modify?(@question)
      flash[:error] = t("global.permission_denied")
      redirect_to question_path(current_languages, @question)
    end
  end

  def check_update_permissions
    @question = Question.find_by_slug_or_id(params[:id])

    if @question.nil?
      redirect_to questions_path
    elsif !(current_user.can_edit_others_posts_on?(@question.group) ||
          current_user.can_modify?(@question))
      reputation = @question.group.reputation_constrains["edit_others_posts"]
      flash[:error] = I18n.t("users.messages.errors.reputation_needed",
                                    :min_reputation => reputation,
                                    :action => I18n.t("users.actions.edit_others_posts"))
      redirect_to question_path(current_languages, @question)
    end
  end

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end

end
