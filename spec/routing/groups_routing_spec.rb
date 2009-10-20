require 'spec_helper'

describe GroupsController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/groups" }.should route_to(:controller => "groups", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/groups/new" }.should route_to(:controller => "groups", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/groups/1" }.should route_to(:controller => "groups", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/groups/1/edit" }.should route_to(:controller => "groups", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/groups" }.should route_to(:controller => "groups", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/groups/1" }.should route_to(:controller => "groups", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/groups/1" }.should route_to(:controller => "groups", :action => "destroy", :id => "1") 
    end
  end
end
