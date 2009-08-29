
$(document).ready(function() {
  $("form.vote_form button").live("click", function(event) {
    var btn_name = $(this).attr("name")
    var form = $(this).parents("form");
    $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
      if(data.status == "ok"){
        form.find("button").remove()
        form.find(".votes_average").text(data.average)
      } else {
        alert(data.message)
      }
    }, "json");
    return false;
  });
});
