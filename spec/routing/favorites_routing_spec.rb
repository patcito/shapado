require 'spec_helper'

describe FavoritesController do
  describe "routing" do
    it "recognizes and generates #index" do
      { :get => "/favorites" }.should route_to(:controller => "favorites", :action => "index")
    end

    it "recognizes and generates #new" do
      { :get => "/favorites/new" }.should route_to(:controller => "favorites", :action => "new")
    end

    it "recognizes and generates #show" do
      { :get => "/favorites/1" }.should route_to(:controller => "favorites", :action => "show", :id => "1")
    end

    it "recognizes and generates #edit" do
      { :get => "/favorites/1/edit" }.should route_to(:controller => "favorites", :action => "edit", :id => "1")
    end

    it "recognizes and generates #create" do
      { :post => "/favorites" }.should route_to(:controller => "favorites", :action => "create") 
    end

    it "recognizes and generates #update" do
      { :put => "/favorites/1" }.should route_to(:controller => "favorites", :action => "update", :id => "1") 
    end

    it "recognizes and generates #destroy" do
      { :delete => "/favorites/1" }.should route_to(:controller => "favorites", :action => "destroy", :id => "1") 
    end
  end
end
