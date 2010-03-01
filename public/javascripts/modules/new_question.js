
$(document).ready(function() {
  $("#ask_question").search({ url : "/questions/related_questions.js",
                              target : $("#related_questions"),
                              behaviour : "focusout",
                              timeout : 10,
                              extraParams : { 'format' : 'js', 'per_page' : 5 }
  });
});
