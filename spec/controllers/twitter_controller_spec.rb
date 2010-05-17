require 'spec_helper'

describe TwitterController do

  #Delete these examples and add some real ones
  it "should use TwitterController" do
    controller.should be_an_instance_of(TwitterController)
  end


  describe "GET 'start'" do
    it "should be successful" do
      get 'start'
      response.should be_success
    end
  end

  describe "GET 'callback'" do
    it "should be successful" do
      get 'callback'
      response.should be_success
    end
  end
end
