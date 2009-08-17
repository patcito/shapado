class QuestionsController < ApplicationController
  before_filter :login_required, :except => [:index, :show]

  # GET /questions
  # GET /questions.xml
  def index
    @questions = Question.paginate(:per_page => 25, :page => params[:page] || 1, :conditions => scoped_conditions)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @questions }
    end
  end

  def unanswered
    @questions = Question.paginate(:per_page => 25, :page => params[:page] || 1, :conditions => scoped_conditions({:answered => false}))
    render :action => "index"
  end

  def tags
    @tag_cloud = Question.tag_cloud
  end

  # GET /questions/1
  # GET /questions/1.xml
  def show
    @question = Question.find_by_slug_or_id(params[:id])
    @answers = @question.answers.paginate(:per_page => 25, :page => params[:page] || 1,
                                          :order => "created_at asc")

    @answer = Answer.new

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @question }
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
    @question = Question.find_by_slug_or_id(params[:id])
  end

  # POST /questions
  # POST /questions.xml
  def create
    @question = Question.new(params[:question])
    @question.user = current_user

    respond_to do |format|
      if @question.save
        flash[:notice] = 'Question was successfully created.'
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
    @question = Question.find_by_slug_or_id(params[:id])

    respond_to do |format|
      if @question.update_attributes(params[:question])
        flash[:notice] = 'Question was successfully updated.'
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
    @question = Question.find_by_slug_or_id(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to(questions_url) }
      format.xml  { head :ok }
    end
  end
end
