$(document).ready(function() {

  $("#search_box .description, #search_box .button").hide()

  $("#search_box input[type=text]").focus(function(event){
  $("#search_box .description, #search_box .button").show()
  });

  $("#search_box .close").click(function(event){
    $("#search_box .description, #search_box .button").hide()
    return false;
  });

  $(".question form.vote-up-form input[name=vote_up]").live("click", function(event) {
    var btn_name = $(this).attr("name");
    var form = $(this).parents("form");
    $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
      if(data.status == "ok"){
        if(data.vote_type == "vote_down") {
          form.html("<img src='/images/dialog-ok-apply.png'/>")
        } else {
          form.html("<img src='/images/dialog-ok-apply.png'/>")
        }
        showMessage(data.message, "notice")
      } else {
        showMessage(data.message, "error")
      }
    }, "json");
    return false;
  });
});
