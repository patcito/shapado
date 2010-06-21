module Support
module Voteable
    def self.included(klass)
    klass.class_eval do
      extend ClassMethods
      include InstanceMethods
      key :votes_count, Integer, :default => 0
      key :votes_average, Integer, :default => 0
      has_many :votes, :as => "voteable", :dependent => :destroy
    end
  end

  module InstanceMethods
    def add_vote!(v, voter)
      self.increment({:votes_count => 1, :votes_average => v.to_i})
      if v > 0
        self.user.upvote!(self.group)
      else
        self.user.downvote!(self.group)
      end
      self.on_add_vote(v, voter) if self.respond_to?(:on_add_vote)
    end

    def remove_vote!(v, voter)
      self.increment({:votes_count => -1, :votes_average => (-v)})
      if v > 0
        self.user.upvote!(self.group, -1)
      else
        self.user.downvote!(self.group, -1)
      end
      self.on_remove_vote(v, voter) if self.respond_to?(:on_remove_vote)
    end
  end

  module ClassMethods
  end
end
end