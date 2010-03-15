class QuestionsController < ApplicationController
  before_filter :login_required, :except => [:create, :index, :show, :tags, :unanswered]
  before_filter :admin_required, :only => [:move, :move_to]
  before_filter :check_permissions, :only => [:solve, :unsolve, :destroy]
  before_filter :check_update_permissions, :only => [:edit, :update, :rollback]
  before_filter :check_favorite_permissions, :only => [:favorite, :unfavorite]
  before_filter :set_active_tag

  tabs :default => :questions, :tags => :tags,
       :unanswered => :unanswered, :new => :ask_question

  subtabs :index => [[:newest, "created_at desc"], [:hot, "hotness desc"], [:votes, "votes_average desc"], [:activity, "activity_at desc"], [:expert, "created_at desc"]],
          :unanswered => [[:newest, "created_at desc"], [:votes, "votes_average desc"], [:mytags, "created_at desc"]],
          :show => [[:votes, "votes_average desc"], [:oldest, "created_at asc"], [:newest, "created_at desc"]]
  helper :votes


  helper :votes

  def history
    @question = current_group.questions.find_by_slug_or_id(params[:id])

    respond_to do |format|
      format.html
      format.json { render :json => @question.versions.to_json }
    end
  end

  def diff
    @question = current_group.questions.find_by_slug_or_id(params[:id])
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

  def rollback
    @question = current_group.questions.find_by_slug_or_id(params[:id])
    @question.updated_by = current_user

    if @question.rollback!(params[:version].to_i)
      flash[:notice] = t(:flash_notice, :scope => "questions.update")
      Magent.push("actors.judge", :on_rollback, @question.id)
    end

    respond_to do |format|
      format.html { redirect_to history_question_path(current_languages, @question) }
    end
  end

  # GET /questions
  # GET /questions.xml
  def index
    set_page_title(t("questions.index.title"))
    conditions = scoped_conditions(:banned => false)

    @questions = Question.paginate({:per_page => 25, :page => params[:page] || 1,
                                   :order => current_order,
                                   :fields => (Question.keys.keys - ["_keywords", "watchers"])}.
                                               merge(conditions))

    @langs_conds = scoped_conditions[:language][:$in]

    add_feeds_url(url_for(:format => "atom", :language=>current_languages), t("feeds.questions"))
    if params[:tags]
      add_feeds_url(url_for(:format => "atom", :tags => params[:tags], :language=>current_languages),
                    "#{t("feeds.tag")} #{params[:tags].inspect}")
    end
    @tag_cloud = Question.tag_cloud(scoped_conditions, 25)

    respond_to do |format|
      format.html # index.html.erb
      format.json  { render :json => @questions.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  def related_questions
    if params[:id]
      @question = Question.find(params[:id])
    elsif params[:question]
      @question = Question.new(params[:question])
      @question.group_id = current_group.id
    end

    @question.tags += @question.title.downcase.split(",").join(" ").split(" ")

    @questions = Question.related_questions(@question, :page => params[:page],
                                                       :per_page => params[:per_page],
                                                       :order => "answers_count desc")

    respond_to do |format|
      format.js do
        render :json => {:html => render_to_string(:partial => "questions/question",
                                                   :collection  => @questions,
                                                   :locals => {:mini => true, :lite => true})}.to_json
      end
    end
  end

  def unanswered
    set_page_title(t("questions.unanswered.title"))
    conditions = scoped_conditions({:answered => false, :banned => false})

    if logged_in?
      if @active_subtab.to_s == "expert"
        conditions[:tags] = {:$all => current_user.stats(:expert_tags).expert_tags}
      elsif @active_subtab.to_s == "mytags"
        conditions[:tags] = {:$all => current_user.preferred_tags_on(current_group)}
      end
    end

    @tag_cloud = Question.tag_cloud({:group_id => current_group.id}.
                    merge(language_conditions.merge(language_conditions)), 25)

    @questions = Question.paginate({:order => current_order,
                                    :per_page => 25,
                                    :page => params[:page] || 1,
                                    :fields => (Question.keys.keys - ["_keywords", "watchers"])
                                   }.merge(conditions))

    respond_to do |format|
      format.html # unanswered.html.erb
      format.json  { render :json => @questions.to_json(:except => %w[_keywords slug watchers]) }
    end
  end

  def tags
    respond_to do |format|
      format.html do
        set_page_title(t("layouts.application.tags"))
        @tag_cloud = Question.tag_cloud({:group_id => current_group.id}.
                        merge(language_conditions.merge(language_conditions)))
      end
      format.js do
        result = []
        if q =params[:prefix]
          result = Question.find_tags(/^#{q}/,
                             :group_id => current_group.id)
        end
        render :text => result.join("\n")
      end
    end
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = current_group.questions.find_by_slug_or_id(params[:id])

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
      format.html { Magent.push("actors.judge", :on_view_question, @question.id) }
      format.json  { render :json => @question.to_json(:except => %w[_keywords slug watchers]) }
      format.atom
    end
  end

  # GET /questions/new
  # GET /questions/new.xml
  def new
    @question = Question.new(params[:question])
    respond_to do |format|
      format.html # new.html.erb
      format.json  { render :json => @question.to_json }
    end
  end

  # GET /questions/1/edit
  def edit
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new
    @question.safe_update(%w[title body language tags wiki], params[:question])
    @question.group = current_group
    @question.user = current_user

    if !logged_in?
      draft = Draft.create!(:question => @question)
      session[:draft] = draft.id
      return login_required
    end

    respond_to do |format|
      if @question.save
        current_user.stats.add_question_tags(*@question.tags)

        current_user.on_activity(:ask_question, current_group)
        current_group.on_activity(:ask_question)

        Magent.push("actors.judge", :on_ask_question, @question.id)

        flash[:notice] = t(:flash_notice, :scope => "questions.create")
        # TODO: move to magent
        users = User.find_experts(@question.tags, [@question.language], :except => [current_user.id])
        users += @question.user.followers

        users.uniq.each do |u|
          if !u.email.blank?
            Notifier.deliver_give_advice(u, current_group, @question)
          end
        end

        format.html { redirect_to(question_path(current_languages, @question)) }
        format.json { render :json => @question.to_json(:except => %w[_keywords watchers]), :status => :created}
      else
        format.html { render :action => "new" }
        format.json { render :json => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    respond_to do |format|
      @question.safe_update(%w[title body language tags wiki], params[:question])
      @question.updated_by = current_user
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

    Magent.push("actors.judge", :on_destroy_question, current_user.id, @question.attributes)

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

        Magent.push("actors.judge", :on_question_solved, @question.id, @answer.id)

        flash[:notice] = t(:flash_notice, :scope => "questions.solve")
        format.html { redirect_to question_path(current_languages, @question) }
        format.json  { head :ok }
      else
        @tag_cloud = Question.tag_cloud(:_id => @question.id)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @question.answer_id} if @question.answer_id
        @answers = @question.answers.paginate(options)
        @answer = Answer.new

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

        Magent.push("actors.judge", :on_question_unsolved, @question.id, @answer_id)

        format.html { redirect_to question_path(current_languages, @question) }
        format.json  { head :ok }
      else
        @tag_cloud = Question.tag_cloud(:_id => @question.id)
        options = {:per_page => 25, :page => params[:page] || 1,
                   :order => current_order, :banned => false}
        options[:_id] = {:$ne => @question.answer_id} if @question.answer_id
        @answers = @question.answers.paginate(options)
        @answer = Answer.new

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

  def favorite
    @favorite = Favorite.new
    @favorite.question_id = @question.id
    @favorite.user = current_user
    @favorite.group = @question.group

    @question.add_watcher(current_user)

    if current_user.notification_opts.activities
      Notifier.deliver_favorited(current_user, @question.group, @question)
    end

    respond_to do |format|
      if @favorite.save
        @question.add_favorite!(@favorite, current_user)
        flash[:notice] = t("favorites.create.success")
        format.html { redirect_to(question_path(current_languages, @question)) }
        format.json { head :ok }
      else
        flash[:error] = @favorite.errors.full_messages.join("**")
        format.html { redirect_to(question_path(current_languages, @question)) }
        format.json { render :json => @favorite.errors, :status => :unprocessable_entity }
      end
    end
  end

  def unfavorite
    @favorite = current_user.favorite(@question)
    if @favorite
      if current_user.can_modify?(@favorite)
        @question.remove_favorite!(@favorite, current_user)
        @favorite.destroy
        @question.remove_watcher(current_user)
      end
    end

    respond_to do |format|
      format.html { redirect_to(question_path(current_languages, @question)) }
      format.json  { head :ok }
    end
  end

  def watch
    @question = Question.find_by_slug_or_id(params[:id])
    @question.add_watcher(current_user)
    flash[:notice] = t("questions.watch.success")
    respond_to do |format|
      format.html {redirect_to question_path(current_languages, @question)}
      format.json { head :ok }
    end
  end

  def unwatch
    @question = Question.find_by_slug_or_id(params[:id])
    @question.remove_watcher(current_user)
    respond_to do |format|
      format.html {redirect_to question_path(current_languages, @question)}
      format.json { head :ok }
    end
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
    @question = current_group.questions.find_by_slug_or_id(params[:id])

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

  def check_favorite_permissions
    @question = current_group.questions.find_by_slug_or_id(params[:id])
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "favorites.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{login_path})"
          redirect_to question_path(current_languages, @question)
        end
        format.json do
          flash[:error] += ", <a href='#{login_path}'> #{t("global.please_login")} </a>"
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end

end
