module VotesHelper
  def vote_box(voteable, source)
    if (logged_in? && voteable.user != current_user) || !logged_in?
      vote = current_user.vote_on(voteable) if logged_in?
      %@
      <form action='#{votes_path}' method='post' class='vote_form' >
        #{token_tag}
        <span class='vote_box'>
          #{hidden_field_tag "voteable_type", voteable.class.name}
          #{hidden_field_tag "voteable_id", voteable.id}
          #{hidden_field_tag "source", source}
          <button type="submit" name="vote_up" value="1" class="arrow">
            #{if vote && vote.value > 0
                image_tag("vote_up.png", :width => 30, :height => 22)
              else
                image_tag("to_vote_up.png", :width => 30, :height => 22)
              end
             }
          </button>
          <div class="votes_average">
            #{calculate_votes_average(voteable)}
          </div>
          <button type="submit" name="vote_down" value="-1" class="arrow">
            #{if vote && vote.value < 0
                image_tag("vote_down.png", :width => 30, :height => 22)
              else
                image_tag("to_vote_down.png", :width => 30, :height => 22)
              end}
          </button>
        </span>
      </form>
      @
    else
      %@
        <span class='vote_box'>
          <div class="arrow">
            #{image_tag("to_vote_up.png", :width => 30, :height => 22)}
          </div>
          <div class="votes_average">
            #{calculate_votes_average(voteable)}
          </div>
          <div class="arrow">
            #{image_tag("to_vote_down.png", :width => 30, :height => 22)}
          </div>
        </span>
      @
    end
  end

  def calculate_votes_average(voteable)
    if voteable.respond_to?(:votes_average)
      voteable.votes_average
    else
      t = 0
      voteable.votes.each {|e| t += e.value }
      t
    end
  end
end
