
$(document).ready(function() {
  $("form.vote_form button").live("click", function(event) {
    var btn_name = $(this).attr("name")
    var form = $(this).parents("form");
    $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
      if(data.status == "ok"){
        form.find(".votes_average").text(data.average)
        if(data.vote_type == "vote_down") {
          form.find("button[name=vote_down] img").attr("src", "/images/vote_down.png")
          form.find("button[name=vote_up] img").attr("src", "/images/to_vote_up.png")
        } else {
          form.find("button[name=vote_up] img").attr("src", "/images/vote_up.png")
          form.find("button[name=vote_down] img").attr("src", "/images/to_vote_down.png")
        }

        showMessage(data.message, "notice")
      } else {
        showMessage(data.message, "error")
      }
    }, "json");
    return false;
  });

  $("form.nestedAnswerForm").hide();
  $(".addNestedAnswer").click(function() {
    $(this).parent().next().next("form.nestedAnswerForm").slideToggle();
    $(this).parents(".flag_form").slideUp();
    return false;
  });


  $(".flag_form .cancel").live("click", function() {
    $(this).parents(".flag_form").slideUp();
    return false;
  });

  $(".flag-link").live("click", function() {
    $(this).parent().next().next("form.nestedAnswerForm").slideUp();
    var form = $(this).parents(".actions").nextAll(".flag_form")
    form.slideToggle();
    return false;
  });
});
