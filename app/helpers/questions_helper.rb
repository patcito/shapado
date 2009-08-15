module QuestionsHelper
  def vote_box(average = 0)
    "<span class='votes'>
      #{link_to "↑", "", :class=> "vote_up"}
      #{average}
      #{link_to "↓", "", :class=>"vote_down"}
    </span>"
  end
end
