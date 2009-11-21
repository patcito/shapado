require 'spec_helper'

describe Favorite do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    Favorite.create!(@valid_attributes)
  end
end
