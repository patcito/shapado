require 'spec_helper'

describe AnnouncementsController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/announcements" }.should route_to(:controller => "announcements", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/announcements/new" }.should route_to(:controller => "announcements", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/announcements/1" }.should route_to(:controller => "announcements", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/announcements/1/edit" }.should route_to(:controller => "announcements", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/announcements" }.should route_to(:controller => "announcements", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/announcements/1" }.should route_to(:controller => "announcements", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/announcements/1" }.should route_to(:controller => "announcements", :action => "destroy", :id => "1") 
    end
  end
end
