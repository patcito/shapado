require 'spec_helper'

describe PagesController do

  def mock_page(stubs={})
    @mock_page ||= mock_model(Page, stubs)
  end

  describe "GET index" do
    it "assigns all pages as @pages" do
      Page.stub(:find).with(:all).and_return([mock_page])
      get :index
      assigns[:pages].should == [mock_page]
    end
  end

  describe "GET show" do
    it "assigns the requested page as @page" do
      Page.stub(:find).with("37").and_return(mock_page)
      get :show, :id => "37"
      assigns[:page].should equal(mock_page)
    end
  end

  describe "GET new" do
    it "assigns a new page as @page" do
      Page.stub(:new).and_return(mock_page)
      get :new
      assigns[:page].should equal(mock_page)
    end
  end

  describe "GET edit" do
    it "assigns the requested page as @page" do
      Page.stub(:find).with("37").and_return(mock_page)
      get :edit, :id => "37"
      assigns[:page].should equal(mock_page)
    end
  end

  describe "POST create" do

    describe "with valid params" do
      it "assigns a newly created page as @page" do
        Page.stub(:new).with({'these' => 'params'}).and_return(mock_page(:save => true))
        post :create, :page => {:these => 'params'}
        assigns[:page].should equal(mock_page)
      end

      it "redirects to the created page" do
        Page.stub(:new).and_return(mock_page(:save => true))
        post :create, :page => {}
        response.should redirect_to(page_url(mock_page))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved page as @page" do
        Page.stub(:new).with({'these' => 'params'}).and_return(mock_page(:save => false))
        post :create, :page => {:these => 'params'}
        assigns[:page].should equal(mock_page)
      end

      it "re-renders the 'new' template" do
        Page.stub(:new).and_return(mock_page(:save => false))
        post :create, :page => {}
        response.should render_template('new')
      end
    end

  end

  describe "PUT update" do

    describe "with valid params" do
      it "updates the requested page" do
        Page.should_receive(:find).with("37").and_return(mock_page)
        mock_page.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :page => {:these => 'params'}
      end

      it "assigns the requested page as @page" do
        Page.stub(:find).and_return(mock_page(:update_attributes => true))
        put :update, :id => "1"
        assigns[:page].should equal(mock_page)
      end

      it "redirects to the page" do
        Page.stub(:find).and_return(mock_page(:update_attributes => true))
        put :update, :id => "1"
        response.should redirect_to(page_url(mock_page))
      end
    end

    describe "with invalid params" do
      it "updates the requested page" do
        Page.should_receive(:find).with("37").and_return(mock_page)
        mock_page.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :page => {:these => 'params'}
      end

      it "assigns the page as @page" do
        Page.stub(:find).and_return(mock_page(:update_attributes => false))
        put :update, :id => "1"
        assigns[:page].should equal(mock_page)
      end

      it "re-renders the 'edit' template" do
        Page.stub(:find).and_return(mock_page(:update_attributes => false))
        put :update, :id => "1"
        response.should render_template('edit')
      end
    end

  end

  describe "DELETE destroy" do
    it "destroys the requested page" do
      Page.should_receive(:find).with("37").and_return(mock_page)
      mock_page.should_receive(:destroy)
      delete :destroy, :id => "37"
    end

    it "redirects to the pages list" do
      Page.stub(:find).and_return(mock_page(:destroy => true))
      delete :destroy, :id => "1"
      response.should redirect_to(pages_url)
    end
  end

end
