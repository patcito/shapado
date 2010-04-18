class CloseRequestsController < ApplicationController
  before_filter :login_required

  def create
    @question = current_group.questions.find_by_slug_or_id(params[:question_id])
    @close_request = CloseRequest.new(:reason => params[:close_request][:reason])
    @close_request.user = current_user
    @question.close_requests << @close_request
    respond_to do |format|
      if @close_request.valid?
        @question.save
        flash[:notice] = t(:flash_notice, :scope => "close_requests.create")
        format.html { redirect_to(question_path(@question)) }
        format.json { render :json => @close_request.to_json, :status => :created}
        format.js { render :json => {:message => flash[:notice], :success => true }.to_json }
      else
        flash[:error] = @close_request.errors.full_messages.join(", ")
        format.html { redirect_to(question_path(@question)) }
        format.json { render :json => @close_request.errors, :status => :unprocessable_entity}
        format.js { render :json => {:message => flash[:error], :success => false }.to_json }
      end
    end
  end

  def update
    @question = current_group.questions.find_by_slug_or_id(params[:question_id])
    @close_request = @question.close_requests.find(params[:id])
    @close_request.reason = params[:close_request][:reason]
    respond_to do |format|
      if @close_request.valid?
        @question.save
        flash[:notice] = t(:flash_notice, :scope => "close_requests.update")
        format.html { redirect_to(question_path(@question)) }
        format.json { render :json => @close_request.to_json}
        format.js { render :json => {:message => flash[:notice], :success => true }.to_json }
      else
        flash[:error] = @close_request.errors.full_messages.join(", ")
        format.html { redirect_to(question_path(@question)) }
        format.json { render :json => @close_request.errors, :status => :unprocessable_entity}
        format.js { render :json => {:message => flash[:error], :success => false }.to_json }
      end
    end
  end

  def destroy
    @question = current_group.questions.find_by_slug_or_id(params[:question_id])
    @close_request = @question.close_requests.find(params[:id])
    @question.close_requests.delete(@close_request)
    @question.save
    flash[:notice] = t(:flash_notice, :scope => "close_requests.destroy")
    respond_to do |format|
      format.html { redirect_to(question_path(@question)) }
      format.json {head :ok}
      format.js { render :json => {:message => flash[:notice], :success => true}.to_json }
    end
  end

  def new
    @question = current_group.questions.find_by_slug_or_id(params[:question_id])
    @close_request = CloseRequest.new(:resource => "dupe")
  end
end
