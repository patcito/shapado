class FavoritesController < ApplicationController
  before_filter :check_permissions, :only => :create
  # POST /favorites
  # POST /favorites.xml
  def create
    @favorite = Favorite.new
    @favorite.question_id = @question.id
    @favorite.user = current_user
    @favorite.group = @question.group

    @question.add_watcher(current_user)

    respond_to do |format|
      if @favorite.save
        @question.add_favorite!(@favorite, current_user)
        flash[:notice] = t("favorites.create.success")
        format.html { redirect_to(question_path(current_category, @question)) }
        format.xml  { render :xml => @favorite, :status => :created, :location => @favorite }
      else
        flash[:error] = @favorite.errors.full_messages.join("**")
        format.html { redirect_to(question_path(current_category, @question)) }
        format.xml  { render :xml => @favorite.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /favorites/1
  # DELETE /favorites/1.xml
  def destroy
    @favorite = Favorite.find(params[:id])
    @question = Question.find_by_slug_or_id(@favorite.question_id)

    @question.remove_favorite!(@favorite, current_user)
    @favorite.destroy
    @question.remove_watcher(current_user)

    respond_to do |format|
      format.html { redirect_to(question_path(current_category, @question)) }
      format.xml  { head :ok }
    end
  end

  protected
  def check_permissions
    @question = Question.find_by_slug_or_id(params[:question_id])
    unless logged_in?
      flash[:error] = t(:unauthenticated, :scope => "favorites.create")
      respond_to do |format|
        format.html do
          flash[:error] += ", [#{t("global.please_login")}](#{login_path})"
          redirect_to question_path(current_category, @question)
        end
        format.json do
          flash[:error] += ", <a href='#{login_path}'> #{t("global.please_login")} </a>"
          render(:json => {:status => :error, :message => flash[:error] }.to_json)
        end
      end
    end
  end
end
