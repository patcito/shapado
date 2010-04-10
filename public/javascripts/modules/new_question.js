
$(document).ready(function() {
  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"))
  });

  $("#ask_question").search({ url : "/questions/related_questions.js",
                              target : $("#related_questions"),
                              behaviour : "focusout",
                              timeout : 2500,
                              extraParams : { 'format' : 'js', 'per_page' : 5 },
                              success: function() {
                                $("label#rqlabel").show();
                              }
  });

  $("#ask_question").bind("keypress", function(e) {
    if (e.keyCode == 13) {
       return false;
     }
  });

});
