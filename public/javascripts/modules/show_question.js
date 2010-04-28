
$(document).ready(function() {
  $("form.nestedAnswerForm").hide();
  $(".forms form.flag_form").hide();
  $("#add_comment_form").hide();
  $("#close_question_form").hide();

  $("form.vote_form button").live("click", function(event) {
    var btn_name = $(this).attr("name")
    var form = $(this).parents("form");
    $.post(form.attr("action")+'.js', form.serialize()+"&"+btn_name+"=1", function(data){
      if(data.success){
        form.find(".votes_average").text(data.average)
        if(data.vote_state == "deleted") {
          form.find("button[name=vote_down] img").attr("src", "/images/to_vote_down.png")
          form.find("button[name=vote_up] img").attr("src", "/images/to_vote_up.png")
        }
        else {
          if(data.vote_type == "vote_down") {
            form.find("button[name=vote_down] img").attr("src", "/images/vote_down.png")
            form.find("button[name=vote_up] img").attr("src", "/images/to_vote_up.png")
          } else {
            form.find("button[name=vote_up] img").attr("src", "/images/vote_up.png")
            form.find("button[name=vote_down] img").attr("src", "/images/to_vote_down.png")
          }
        }
        showMessage(data.message, "notice")
      } else {
        showMessage(data.message, "error")
        if(data.status == "unauthenticate") {
          window.location="/users/login"
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
                      window.location="/users/login"
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
                              window.location="/users/login"
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

  $("#request_close_question_form").submit(function() {
    var request_button = $(this).find("input.button")
    request_button.attr('disabled', true)
    var close_button = $(this).find("button")
    close_button.attr('disabled', true)
    form = $(this)

    $.ajax({
      url: $(this).attr("action"),
      data: $(this).serialize()+"&format=js",
      dataType: "json",
      type: "POST",
      success: function(data, textStatus, XMLHttpRequest) {
        if(data.success) {
          form.slideUp()
          showMessage(data.message, "notice")
        } else {
          showMessage(data.message, "error")
          if(data.status == "unauthenticate") {
            window.location="/users/login"
          }
        }
      },
      error: manageAjaxError,
      complete: function(XMLHttpRequest, textStatus) {
        request_button.attr('disabled', false)
        close_button.attr('disabled', false)
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
                              if(data.success) {
                                comment.find(".markdown").html('<p>'+data.body+'</p>');
                                form.remove();
                                link.show();
                                highlightEffect(comment);
                                showMessage(data.message, "notice");
                              } else {
                                showMessage(data.message, "error")
                                if(data.status == "unauthenticate") {
                                  window.location="/users/login"
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
    var link = $(this);
    var user = link.attr('data-author');
    var isreply = link.hasClass('reply');
    var controls = link.parents(".controls");
    var form = controls.parents(".answer").find("form.nestedAnswerForm");
    if(form.length == 0) // if comment is child of a question
      form = controls.parents("#question-body-col").find("form.commentForm");
    var textarea = form.find('textarea');
    var isHidden = !form.is(':visible');
    controls.find(".forms form.flag_form").slideUp();
    form.slideDown();
    if(isreply){
      textarea.focus();
      textarea.text('@'+user+' ')
    } else { textarea.text('').focus();  }

    var top = textarea.offset().top;
    $('html,body').animate({scrollTop: top-50}, 1000);
    return false;
  });

  $("#add_comment_link").live('click', function() {
    var link = $(this);
    var user = link.attr('data-author');
    var isreply = link.hasClass('reply');
    var controls = link.parents(".controls");
    var form = controls.parents("#question-body-col").find("form.commentForm");
    var textarea = form.find('textarea');
    $("#request_close_question_form").slideUp();
    $("#question_flag_form").slideUp();
    $("#close_question_form").slideUp();
    $("#add_comment_form").slideDown();
    textarea.text('').focus();
    var top = textarea.offset().top;
    $('html,body').animate({scrollTop: top-50}, 1000);
    return false;
  });

  $('.cancel_comment').live('click', function(){
    $(this).parents('form').slideUp();
    return false;
  });

  $(".flag_form .cancel").live("click", function() {
    $(this).parents(".flag_form").slideUp();
    return false;
  });

  $(".answer .flag-link").live("click", function() {
    var link = $(this);
    var controls = link.parents(".controls")
    controls.find(".forms form.nestedAnswerForm").slideUp();
    controls.parents(".answer").find(".forms .flag_form").slideToggle();

    return false;
  });

  $("#close_question_link").click(function() {
    $("#request_close_question_form").slideUp();
    $("#add_comment_form").slideUp();
    $("#question_flag_form").slideUp();
    $("#close_question_form").slideToggle();
    return false;
  });

  $("#question_flag_link.flag-link").click(function() {
    $("#request_close_question_form").slideUp();
    $("#add_comment_form").slideUp();
    $("#close_question_form").slideUp();
    $("#question_flag_form").slideToggle();
    return false;
  });

  $("#request-close-link").click(function() {
    var controls = $(this).parents(".controls")
    $("#add_comment_form").slideUp();
    $("#question_flag_form").slideUp();
    $("#close_question_form").slideUp();
    $("#request_close_question_form").slideToggle();
    return false;
  });

  $(".question-action").live("click", function(event) {
    var link = $(this);
    if(!link.hasClass('busy')){
      link.addClass('busy');
      var href = link.attr("href");
      var dataUndo = link.attr("data-undo");
      var title = link.attr("title");
      var dataTitle = link.attr("data-title");
      var img = link.children('img');
      var counter = $(link.attr('data-counter'));
      $.getJSON(href+'.js', function(data){
        if(data.success){
          link.attr({href: dataUndo, 'data-undo': href, title: dataTitle, 'data-title': title });
          img.attr({src: img.attr('data-src'), 'data-src': img.attr('src')});
          if(typeof(data.increment)!='undefined'){
            counter.text(parseFloat($.trim(counter.text()))+data.increment);
          }
          showMessage(data.message, "notice");
        } else {
          showMessage(data.message, "error");

          if(data.status == "unauthenticate") {
            window.location="/users/login";
          }
        }
        link.removeClass('busy');
        }, "json");
      }
    return false;
  });

$('#retag').live('click',function(){
  var link = $(this);
  $.ajax({
    dataType: "json",
    type: "GET",
    url : link.attr('href'),
    extraParams : { 'format' : 'js'},
    success: function(data) {
      if(data.success){
        link.parents(".tag-list").find('.tag').hide();
        $('.retag').hide();
        link.parents(".tag-list").prepend(data.html);
        initAutocomplete();
      } else {
          showMessage(data.message, "error");
          if(data.status == "unauthenticate") {
            window.location="/users/login"
          }
      }
    }
  });
  return false;
})

$('.retag-form').live('submit', function() {
    form = $(this);
    var button = form.find('input[type=submit]');
    button.attr('disabled', true)
    $.ajax({url: form.attr("action")+'.js',
            dataType: "json",
            type: "POST",
            data: form.serialize()+"&format=js",
            success: function(data, textStatus) {
                if(data.success) {
                    var tags = $.map(data.tags, function(n){
                        return '<span class="tag"><a rel="tag" href="/questions/tags/'+n+'">'+n+'</a></span>'
                    })
                    form.parents('.tag-list').find('.tag').remove();
                    form.before(tags.join(''));
                    form.remove();
                    $('.retag').show();
                    showMessage(data.message, "notice")
                } else {
                    showMessage(data.message, "error")
                    if(data.status == "unauthenticate") {
                        window.location="/users/login"
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

  $('.cancel-retag').live('click', function(){
      var link = $(this);
      link.parents('.tag-list').find('.tag').show();
      link.parents('.tag-list').find('.retag').show();
      link.parents('.tag-list').find('form').remove();
      return false;
  })

});

