require 'spec_helper'

describe FavoritesController do

  def mock_favorite(stubs={})
    @mock_favorite ||= mock_model(Favorite, stubs)
  end

  describe "GET index" do
    it "assigns all favorites as @favorites" do
      Favorite.stub!(:find).with(:all).and_return([mock_favorite])
      get :index
      assigns[:favorites].should == [mock_favorite]
    end
  end

  describe "GET show" do
    it "assigns the requested favorite as @favorite" do
      Favorite.stub!(:find).with("37").and_return(mock_favorite)
      get :show, :id => "37"
      assigns[:favorite].should equal(mock_favorite)
    end
  end

  describe "GET new" do
    it "assigns a new favorite as @favorite" do
      Favorite.stub!(:new).and_return(mock_favorite)
      get :new
      assigns[:favorite].should equal(mock_favorite)
    end
  end

  describe "GET edit" do
    it "assigns the requested favorite as @favorite" do
      Favorite.stub!(:find).with("37").and_return(mock_favorite)
      get :edit, :id => "37"
      assigns[:favorite].should equal(mock_favorite)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created favorite as @favorite" do
        Favorite.stub!(:new).with({'these' => 'params'}).and_return(mock_favorite(:save => true))
        post :create, :favorite => {:these => 'params'}
        assigns[:favorite].should equal(mock_favorite)
      end

      it "redirects to the created favorite" do
        Favorite.stub!(:new).and_return(mock_favorite(:save => true))
        post :create, :favorite => {}
        response.should redirect_to(favorite_url(mock_favorite))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved favorite as @favorite" do
        Favorite.stub!(:new).with({'these' => 'params'}).and_return(mock_favorite(:save => false))
        post :create, :favorite => {:these => 'params'}
        assigns[:favorite].should equal(mock_favorite)
      end

      it "re-renders the 'new' template" do
        Favorite.stub!(:new).and_return(mock_favorite(:save => false))
        post :create, :favorite => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested favorite" do
        Favorite.should_receive(:find).with("37").and_return(mock_favorite)
        mock_favorite.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :favorite => {:these => 'params'}
      end

      it "assigns the requested favorite as @favorite" do
        Favorite.stub!(:find).and_return(mock_favorite(:update_attributes => true))
        put :update, :id => "1"
        assigns[:favorite].should equal(mock_favorite)
      end

      it "redirects to the favorite" do
        Favorite.stub!(:find).and_return(mock_favorite(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(favorite_url(mock_favorite))
      end
    end

    describe "with invalid params" do
      it "updates the requested favorite" do
        Favorite.should_receive(:find).with("37").and_return(mock_favorite)
        mock_favorite.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :favorite => {:these => 'params'}
      end

      it "assigns the favorite as @favorite" do
        Favorite.stub!(:find).and_return(mock_favorite(:update_attributes => false))
        put :update, :id => "1"
        assigns[:favorite].should equal(mock_favorite)
      end

      it "re-renders the 'edit' template" do
        Favorite.stub!(:find).and_return(mock_favorite(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested favorite" do
      Favorite.should_receive(:find).with("37").and_return(mock_favorite)
      mock_favorite.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the favorites list" do
      Favorite.stub!(:find).and_return(mock_favorite(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(favorites_url)
    end
  end

end
