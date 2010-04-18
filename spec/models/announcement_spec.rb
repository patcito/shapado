require 'spec_helper'

describe Announcement do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    Announcement.create!(@valid_attributes)
  end
end
