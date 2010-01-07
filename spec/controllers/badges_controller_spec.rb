require 'spec_helper'

describe BadgesController do

  def mock_badge(stubs={})
    @mock_badge ||= mock_model(Badge, stubs)
  end

  describe "GET index" do
    it "assigns all badges as @badges" do
      Badge.stub!(:find).with(:all).and_return([mock_badge])
      get :index
      assigns[:badges].should == [mock_badge]
    end
  end

  describe "GET show" do
    it "assigns the requested badge as @badge" do
      Badge.stub!(:find).with("37").and_return(mock_badge)
      get :show, :id => "37"
      assigns[:badge].should equal(mock_badge)
    end
  end

  describe "GET new" do
    it "assigns a new badge as @badge" do
      Badge.stub!(:new).and_return(mock_badge)
      get :new
      assigns[:badge].should equal(mock_badge)
    end
  end

  describe "GET edit" do
    it "assigns the requested badge as @badge" do
      Badge.stub!(:find).with("37").and_return(mock_badge)
      get :edit, :id => "37"
      assigns[:badge].should equal(mock_badge)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created badge as @badge" do
        Badge.stub!(:new).with({'these' => 'params'}).and_return(mock_badge(:save => true))
        post :create, :badge => {:these => 'params'}
        assigns[:badge].should equal(mock_badge)
      end

      it "redirects to the created badge" do
        Badge.stub!(:new).and_return(mock_badge(:save => true))
        post :create, :badge => {}
        response.should redirect_to(badge_url(mock_badge))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved badge as @badge" do
        Badge.stub!(:new).with({'these' => 'params'}).and_return(mock_badge(:save => false))
        post :create, :badge => {:these => 'params'}
        assigns[:badge].should equal(mock_badge)
      end

      it "re-renders the 'new' template" do
        Badge.stub!(:new).and_return(mock_badge(:save => false))
        post :create, :badge => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested badge" do
        Badge.should_receive(:find).with("37").and_return(mock_badge)
        mock_badge.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :badge => {:these => 'params'}
      end

      it "assigns the requested badge as @badge" do
        Badge.stub!(:find).and_return(mock_badge(:update_attributes => true))
        put :update, :id => "1"
        assigns[:badge].should equal(mock_badge)
      end

      it "redirects to the badge" do
        Badge.stub!(:find).and_return(mock_badge(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(badge_url(mock_badge))
      end
    end

    describe "with invalid params" do
      it "updates the requested badge" do
        Badge.should_receive(:find).with("37").and_return(mock_badge)
        mock_badge.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :badge => {:these => 'params'}
      end

      it "assigns the badge as @badge" do
        Badge.stub!(:find).and_return(mock_badge(:update_attributes => false))
        put :update, :id => "1"
        assigns[:badge].should equal(mock_badge)
      end

      it "re-renders the 'edit' template" do
        Badge.stub!(:find).and_return(mock_badge(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested badge" do
      Badge.should_receive(:find).with("37").and_return(mock_badge)
      mock_badge.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the badges list" do
      Badge.stub!(:find).and_return(mock_badge(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(badges_url)
    end
  end

end
