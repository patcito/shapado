module QuestionsHelper
  def vote_box(average = 0)
    %@<span class='votes'>
      #{link_to image_tag("vote_up.png", :width => 34, :height => 22), "", :class=> "vote_up", :style => "display:block", :title => "Vote Up"}
      <span style="display:block">
        #{average}
      </span>
      #{link_to image_tag("vote_down.png", :width => 30, :height => 22), "", :class=>"vote_down", :style => "display:block", :title => "Vote Down"}
    </span>@
  end
end
