require 'spec_helper'

describe AnnouncementsController do

  def mock_announcement(stubs={})
    @mock_announcement ||= mock_model(Announcement, stubs)
  end

  describe "GET index" do
    it "assigns all announcements as @announcements" do
      Announcement.stub(:find).with(:all).and_return([mock_announcement])
      get :index
      assigns[:announcements].should == [mock_announcement]
    end
  end

  describe "GET show" do
    it "assigns the requested announcement as @announcement" do
      Announcement.stub(:find).with("37").and_return(mock_announcement)
      get :show, :id => "37"
      assigns[:announcement].should equal(mock_announcement)
    end
  end

  describe "GET new" do
    it "assigns a new announcement as @announcement" do
      Announcement.stub(:new).and_return(mock_announcement)
      get :new
      assigns[:announcement].should equal(mock_announcement)
    end
  end

  describe "GET edit" do
    it "assigns the requested announcement as @announcement" do
      Announcement.stub(:find).with("37").and_return(mock_announcement)
      get :edit, :id => "37"
      assigns[:announcement].should equal(mock_announcement)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created announcement as @announcement" do
        Announcement.stub(:new).with({'these' => 'params'}).and_return(mock_announcement(:save => true))
        post :create, :announcement => {:these => 'params'}
        assigns[:announcement].should equal(mock_announcement)
      end

      it "redirects to the created announcement" do
        Announcement.stub(:new).and_return(mock_announcement(:save => true))
        post :create, :announcement => {}
        response.should redirect_to(announcement_url(mock_announcement))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved announcement as @announcement" do
        Announcement.stub(:new).with({'these' => 'params'}).and_return(mock_announcement(:save => false))
        post :create, :announcement => {:these => 'params'}
        assigns[:announcement].should equal(mock_announcement)
      end

      it "re-renders the 'new' template" do
        Announcement.stub(:new).and_return(mock_announcement(:save => false))
        post :create, :announcement => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested announcement" do
        Announcement.should_receive(:find).with("37").and_return(mock_announcement)
        mock_announcement.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :announcement => {:these => 'params'}
      end

      it "assigns the requested announcement as @announcement" do
        Announcement.stub(:find).and_return(mock_announcement(:update_attributes => true))
        put :update, :id => "1"
        assigns[:announcement].should equal(mock_announcement)
      end

      it "redirects to the announcement" do
        Announcement.stub(:find).and_return(mock_announcement(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(announcement_url(mock_announcement))
      end
    end

    describe "with invalid params" do
      it "updates the requested announcement" do
        Announcement.should_receive(:find).with("37").and_return(mock_announcement)
        mock_announcement.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :announcement => {:these => 'params'}
      end

      it "assigns the announcement as @announcement" do
        Announcement.stub(:find).and_return(mock_announcement(:update_attributes => false))
        put :update, :id => "1"
        assigns[:announcement].should equal(mock_announcement)
      end

      it "re-renders the 'edit' template" do
        Announcement.stub(:find).and_return(mock_announcement(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested announcement" do
      Announcement.should_receive(:find).with("37").and_return(mock_announcement)
      mock_announcement.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the announcements list" do
      Announcement.stub(:find).and_return(mock_announcement(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(announcements_url)
    end
  end

end
