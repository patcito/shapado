require 'spec_helper'

describe BadgesController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/badges" }.should route_to(:controller => "badges", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/badges/new" }.should route_to(:controller => "badges", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/badges/1" }.should route_to(:controller => "badges", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/badges/1/edit" }.should route_to(:controller => "badges", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/badges" }.should route_to(:controller => "badges", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/badges/1" }.should route_to(:controller => "badges", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/badges/1" }.should route_to(:controller => "badges", :action => "destroy", :id => "1") 
    end
  end
end
