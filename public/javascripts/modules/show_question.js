
$(document).ready(function() {
  $("form.nestedAnswerForm").hide();
  $("form.flag_form").hide();
  $("#add_comment_form").hide();

  $("form.vote_form button").live("click", function(event) {
    var btn_name = $(this).attr("name")
    var form = $(this).parents("form");
    $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
      if(data.success){
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
        if(data.status == "unauthenticate") {
          window.location="/login"
        }
      }
    }, "json");
    return false;
  });

  $("form.mainAnswerForm .button").live("click", function(event) {
    var form = $(this).parents("form");
    var answers = $("#answers .block");
    var button = $(this)

    button.attr('disabled', true)
    $.ajax({ url: form.attr("action"),
      data: form.serialize()+"&format=js",
      dataType: "json",
      type: "POST",
      success: function(data, textStatus, XMLHttpRequest) {
                  if(data.success) {
                    var answer = $(data.html)
                    answer.find("form.commentForm").hide();
                    answers.append(answer)
                    highlightEffect(answer)
                    showMessage(data.message, "notice")
                    form.find("textarea").text("");
                    form.find("#markdown_preview").html("");
                  } else {
                    showMessage(data.message, "error")
                    if(data.status == "unauthenticate") {
                      window.location="/login"
                    }
                  }
                },
      error: manageAjaxError,
      complete: function(XMLHttpRequest, textStatus) {
         button.attr('disabled', false)
      }
    });
    return false;
  });

  $("form.commentForm .button").live("click", function(event) {
    var form = $(this).parents("form");
    var commentable = $(this).parents(".commentable");
    var comments = commentable.find(".comments")
    var button = $(this)

    button.attr('disabled', true)
    $.ajax({ url: form.attr("action"),
             data: form.serialize()+"&format=js",
             dataType: "json",
             type: "POST",
             success: function(data, textStatus, XMLHttpRequest) {
                          if(data.success) {
                            var comment = $(data.html)
                            comments.append(comment)
                            highlightEffect(comment)
                            showMessage(data.message, "notice")
                            form.hide();
                            form.find("textarea").val("");
                          } else {
                            showMessage(data.message, "error")
                            if(data.status == "unauthenticate") {
                              window.location="/login"
                            }
                          }
                      },
             error: manageAjaxError,
             complete: function(XMLHttpRequest, textStatus) {
               button.attr('disabled', false)
             }
    });
    return false;
  });

  $(".edit_comment").live("click", function() {
    var comment = $(this).parents(".comment")
    var link = $(this)
    link.hide()
    $.ajax({
      url: $(this).attr("href"),
      dataType: "json",
      type: "GET",
      data: {format: 'js'},
      success: function(data) {
        comment = comment.append(data.html);
        link.hide()
        var form = comment.find("form.form")
        form.find(".cancel_edit_comment").click(function() {
          form.remove();
          link.show();
          return false;
        });

        var button = form.find("input[type=submit]");

        form.submit(function() {
          button.attr('disabled', true)
          $.ajax({url: form.attr("action"),
                  dataType: "json",
                  type: "PUT",
                  data: form.serialize()+"&format=js",
                  success: function(data, textStatus) {
                              if(data.sucess) {
                                comment.find(".markdown p").html(data.body);
                                form.remove();
                                link.show();
                                highlightEffect(comment)
                              } else {
                                showMessage(data.message, "error")
                                if(data.status == "unauthenticate") {
                                  window.location="/login"
                                }
                              }
                            },
                  error: manageAjaxError,
                  complete: function(XMLHttpRequest, textStatus) {
                    button.attr('disabled', false)
                  }
           });
           return false
        });
      },
      error: manageAjaxError,
      complete: function(XMLHttpRequest, textStatus) {
        link.show()
      }
    });
    return false;
  });

  $(".addNestedAnswer").live("click", function() {
    var controls = $(this).parents(".controls")
    controls.find(".forms form.flag_form").slideUp();
    controls.find("form.nestedAnswerForm").slideToggle();
    return false;
  });

  $(".flag_form .cancel").live("click", function() {
    $(this).parents(".flag_form").slideUp();
    return false;
  });

  $(".flag-link").live("click", function() {
    var controls = $(this).parents(".controls")
    controls.find(".forms form.nestedAnswerForm").slideUp();
    controls.find(".forms .flag_form").slideToggle();
    return false;
  });

  $("#question_flag_link").click(function() {
    $("#add_comment_form").slideUp();
    $("#question_flag_form").slideToggle();
    return false;
  });

  $("#add_comment_link").click(function() {
    var controls = $(this).parents(".controls")
    controls.find(".forms form.nestedAnswerForm").slideUp();
    controls.find(".forms .flag_form").slideUp();
    $("#add_comment_form").slideToggle();
    return false;
  });
});

