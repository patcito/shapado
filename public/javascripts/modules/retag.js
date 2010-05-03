$(document).ready(function() {
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