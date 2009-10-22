require 'spec_helper'

describe GroupsController do

  def mock_group(stubs={})
    @mock_group ||= mock_model(Group, stubs)
  end

  describe "GET index" do
    it "assigns all groups as @groups" do
      Group.stub!(:find).with(:all).and_return([mock_group])
      get :index
      assigns[:groups].should == [mock_group]
    end
  end

  describe "GET show" do
    it "assigns the requested group as @group" do
      Group.stub!(:find).with("37").and_return(mock_group)
      get :show, :id => "37"
      assigns[:group].should equal(mock_group)
    end
  end

  describe "GET new" do
    it "assigns a new group as @group" do
      Group.stub!(:new).and_return(mock_group)
      get :new
      assigns[:group].should equal(mock_group)
    end
  end

  describe "GET edit" do
    it "assigns the requested group as @group" do
      Group.stub!(:find).with("37").and_return(mock_group)
      get :edit, :id => "37"
      assigns[:group].should equal(mock_group)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created group as @group" do
        Group.stub!(:new).with({'these' => 'params'}).and_return(mock_group(:save => true))
        post :create, :group => {:these => 'params'}
        assigns[:group].should equal(mock_group)
      end

      it "redirects to the created group" do
        Group.stub!(:new).and_return(mock_group(:save => true))
        post :create, :group => {}
        response.should redirect_to(group_url(mock_group))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved group as @group" do
        Group.stub!(:new).with({'these' => 'params'}).and_return(mock_group(:save => false))
        post :create, :group => {:these => 'params'}
        assigns[:group].should equal(mock_group)
      end

      it "re-renders the 'new' template" do
        Group.stub!(:new).and_return(mock_group(:save => false))
        post :create, :group => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested group" do
        Group.should_receive(:find).with("37").and_return(mock_group)
        mock_group.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :group => {:these => 'params'}
      end

      it "assigns the requested group as @group" do
        Group.stub!(:find).and_return(mock_group(:update_attributes => true))
        put :update, :id => "1"
        assigns[:group].should equal(mock_group)
      end

      it "redirects to the group" do
        Group.stub!(:find).and_return(mock_group(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(group_url(mock_group))
      end
    end

    describe "with invalid params" do
      it "updates the requested group" do
        Group.should_receive(:find).with("37").and_return(mock_group)
        mock_group.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :group => {:these => 'params'}
      end

      it "assigns the group as @group" do
        Group.stub!(:find).and_return(mock_group(:update_attributes => false))
        put :update, :id => "1"
        assigns[:group].should equal(mock_group)
      end

      it "re-renders the 'edit' template" do
        Group.stub!(:find).and_return(mock_group(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested group" do
      Group.should_receive(:find).with("37").and_return(mock_group)
      mock_group.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the groups list" do
      Group.stub!(:find).and_return(mock_group(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(groups_url)
    end
  end

end
