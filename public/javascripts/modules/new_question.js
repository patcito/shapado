
$(document).ready(function() {
  $("label#rqlabel").hide();

  $(".text_field#question_title").focus( function() {
    highlightEffect($("#sidebar .help"))
  });

  $("#ask_question").searcher({ url : "/questions/related_questions.js",
                              target : $("#related_questions"),
                              fields : $("input[type=text][name*=question]"),
                              behaviour : "focusout",
                              timeout : 2500,
                              extraParams : { 'format' : 'js', 'per_page' : 5 },
                              success: function(data) {
                                $("label#rqlabel").show();
                              }
  });

  $("#ask_question").bind("keypress", function(e) {
    if (e.keyCode == 13) {
       return false;
     }
  });

});
