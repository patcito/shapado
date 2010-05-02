require File.dirname(__FILE__)+"/env"
require File.dirname(__FILE__)+"/judge/questions"
require File.dirname(__FILE__)+"/judge/activities"
require File.dirname(__FILE__)+"/judge/votes"
require File.dirname(__FILE__)+"/judge/users"

module Actors
  # /actors/judge
  class Judge
    include Magent::Actor
    include JudgeActions::Questions
    include JudgeActions::Activities
    include JudgeActions::Votes
    include JudgeActions::Users

    expose :on_question_solved
    expose :on_question_unsolved
    expose :on_view_question
    expose :on_ask_question
    expose :on_destroy_question
    expose :on_question_favorite
    expose :on_retag_question

    expose :on_update_user

    expose :on_activity
    expose :on_comment
    expose :on_follow
    expose :on_unfollow
    expose :on_flag
    expose :on_rollback

    expose :on_vote_question
    expose :on_vote_answer

    expose :on_destroy_answer
    expose :on_update_answer

    private
    def create_badge(user, group, opts, check_opts = {})
      unique = opts.delete(:unique) || check_opts.delete(:unique)

      ok = true
      if unique
        ok = user.find_badge_on(group, opts[:token], check_opts).nil?
      end

      return unless ok

      badge = user.badges.create!(opts.merge({:group_id => group.id}))
      if !badge.valid?
        puts "Cannot create the #{badge.token} badge: #{badge.errors.full_messages}"
      end

      if !badge.new? && !user.email.blank? && user.notification_opts.activities
        Notifier.deliver_earned_badge(user, group, badge)
      end
    end
  end
  Magent.register(Judge.new)
end

if $0 == __FILE__
  Magent::Processor.new(Magent.current_actor).run!
end
