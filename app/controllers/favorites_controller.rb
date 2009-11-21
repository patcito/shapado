class FavoritesController < ApplicationController
  # POST /favorites
  # POST /favorites.xml
  def create
    @question = Question.find_by_slug_or_id(params[:question_id])
    @favorite = Favorite.new
    @favorite.question_id = @question.id
    @favorite.user = current_user
    @favorite.group = @question.group

    respond_to do |format|
      if @favorite.save!
        @question.add_favorite!(@favorite, current_user)
        flash[:notice] = 'Favorite was successfully created.'
        format.html { redirect_to(question_path(current_category, @question)) }
        format.xml  { render :xml => @favorite, :status => :created, :location => @favorite }
      else
        format.html { render :action => "show", :controller => "Questions", :id => question.id }
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

    respond_to do |format|
      format.html { redirect_to(question_path(current_category, @question)) }
      format.xml  { head :ok }
    end
  end
end
