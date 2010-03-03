
$(document).ready(function() {
  $("#quick_question #tags, #quick_question .ask_question").hide();
  $("#question_title").focus(function(event) {
    $("#quick_question #tags, #quick_question .ask_question").show();
  });
});
