class QuestionsController < ApplicationController
  before_filter :login_required, :except => [:index, :show, :tags, :unanswered]
  before_filter :check_permissions, :only => [:edit, :update, :solve, :unsolve, :destroy]
  before_filter :set_active_tag
  before_filter :categories_required

  tabs :default => :questions, :tags => :tags,
       :unanswered => :unanswered, :new => :ask_question

  helper :votes

  # GET /questions
  # GET /questions.xml
  def index
    set_page_title(t("views.questions.index.title"))
    order = "created_at desc"
    @active_subtab = params.fetch(:sort, "newest")
    case @active_subtab
      when "active"
        order = "activity_at desc"
      when "votes"
        order = "votes_count desc"
      when "hot"
        order = "hotness desc"
    end

    @questions = Question.paginate(:per_page => 25, :page => params[:page] || 1,
                                   :order => order,
                                   :conditions => scoped_conditions(:banned => false))

    @langs_conds = scoped_conditions[:language]

    add_feeds_url(url_for(:format => "atom", :language=>@langs_conds), t("views.feeds.questions"))
    if params[:tags]
      add_feeds_url(url_for(:format => "atom", :tags => params[:tags], :language=>@langs_conds),
                    "#{t("views.feeds.tag")} #{params[:tags].inspect}")
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questions }
      format.atom
    end
  end

  def unanswered
    @questions = Question.paginate(:per_page => 25, :page => params[:page] || 1, :conditions => scoped_conditions({:answered => false}))
    render :action => "index"
  end

  def tags
    set_page_title(t("views.layout.tags"))
    @tag_cloud = Question.tag_cloud(language_conditions.merge(categories_conditions))
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    order = "created_at desc"
    @active_subtab = params.fetch(:sort, "newest")
    case @active_subtab
      when "oldest"
        order = "created_at asc"
      when "newest"
        order = "created_at desc"
      when "votes"
        order = "votes_count desc"
    end

    @question = Question.find_by_slug_or_id(params[:id])
    @answers = @question.answers.paginate(:per_page => 25, :page => params[:page] || 1,
                                          :order => order,
                                          :conditions => {:banned => false})

    @answer = Answer.new
    @question.viewed!

    set_page_title(@question.title)
    add_feeds_url(url_for(:format => "atom"), t("views.feeds.question"))

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
      format.atom
    end
  end

  # GET /questions/new
  # GET /questions/new.xml
  def new
    @question = Question.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @question }
    end
  end

  # GET /questions/1/edit
  def edit
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new
    @question.safe_update(%w[title body language category tags], params[:question])
    @question.user = current_user

    respond_to do |format|
      if @question.save
        current_user.update_reputation(:ask_question)
        flash[:notice] = t(:flash_notice, :scope => "views.questions.create")

        format.html { redirect_to(@question) }
        format.xml  { render :xml => @question, :status => :created, :location => @question }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.xml
  def update
    respond_to do |format|
      @question.safe_update(%w[title body language category tags], params[:question])
      if @question.valid? && @question.save
        flash[:notice] = t(:flash_notice, :scope => "views.questions.update")
        format.html { redirect_to(@question) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @question.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.xml
  def destroy
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(questions_url) }
      format.xml  { head :ok }
    end
  end

  def solve
    @answer = @question.answers.find(params[:answer_id])
    @question.answer = @answer
    @question.answered = true

    respond_to do |format|
      if @question.save
        current_user.update_reputation(:close_question)
        if current_user != @answer.user
          @answer.user.update_reputation(:answer_picked_as_solution)
        end
        flash[:notice] = t(:flash_notice, :scope => "views.questions.solve")
        format.html { redirect_to question_path(@question) }
      else
        format.html { render :action => "show" }
      end
    end
  end

  def unsolve
    answer_owner = @question.answer.user
    @question.answer = nil
    @question.answered = false

    respond_to do |format|
      if @question.save
        flash[:notice] = t(:flash_notice, :scope => "views.questions.unsolve")
        current_user.update_reputation(:reopen_question)
        if current_user != answer_owner
          answer_owner.update_reputation(:answer_unpicked_as_solution)
        end
        format.html { redirect_to question_path(@question) }
      else
        format.html { render :action => "show" }
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
    end
  end

  protected
  def check_permissions
    @question = Question.find_by_slug_or_id(params[:id])

    if @question.nil?
      redirect_to questions_path
    elsif !current_user.can_modify?(@question)
      flash[:error] = t("views.layout.permission_denied")
      redirect_to question_path(@question)
    end
  end

  def set_active_tag
    @active_tag = "tag_#{params[:tags]}" if params[:tags]
    @active_tag
  end
end
