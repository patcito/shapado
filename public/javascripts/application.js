$(document).ready(function() {
  $("form.nestedAnswerForm").hide();
  $("#add_comment_form").hide();
  $("form").live('submit', function() {
    var textarea = $(this).find('textarea');
    removeFromLocalStorage(location.href, textarea.attr('id'));
    window.onbeforeunload = null;
  });

  $('.confirm-domain').submit(function(){
      var bool = confirm($(this).attr('data-confirm'));
      if(bool==false) return false;

  })
  $("#feedbackform").dialog({ title: "Feedback", autoOpen: false, modal: true, width:"420px" })
  $('#feedbackform .cancel-feedback').click(function(){
    $("#feedbackform").dialog('close');
    return false;
  })
  $('#feedback').click(function(){
    var isOpen = $("#feedbackform").dialog('isOpen');
    if (isOpen){
      $("#feedbackform").dialog('close');
    } else {
      $("#feedbackform").dialog('open');
    }
    return false;
  })

  initAutocomplete();

  $(".quick-vote-button").live("click", function(event) {
    var btn = $(this);
    btn.hide();
    var src = btn.attr('src');
    if (src.indexOf('/images/dialog-ok.png') == 0){
      var btn_name = $(this).attr("name")
      var form = $(this).parents("form");
      $.post(form.attr("action"), form.serialize()+"&"+btn_name+"=1", function(data){
        if(data.success){
          btn.parents('.item').find('.votes .counter').text(data.average);
          btn.attr('src', '/images/dialog-ok-apply.png');
          showMessage(data.message, "notice")
        } else {
          showMessage(data.message, "error")
          if(data.status == "unauthenticate") {
            window.onbeforeunload = null;
            window.location="/users/login"
          }
        }
        btn.show();
      }, "json");
    }
    return false;
  });

  $("a#hide_announcement").click(function() {
    $("#announcement").fadeOut();
    $.post($(this).attr("href"), "format=js");
    return false;
  });

  $('textarea').live('keyup',function(){
      var value = $(this).val();
      var id = $(this).attr('id');
      addToLocalStorage(location.href, id, value);
  })

  initStorageMethods();
  fillTextareas();

  $(".highlight_for_user").effect("highlight", {}, 2000);
  sortValues('group_language', ':last');
  sortValues('language_filter', ':lt(2)');
  sortValues('user_language', false);

  $('.langbox.jshide').hide();
  $('.show-more-lang').click(function(){
      $('.langbox.jshide').toggle();
      return false;
  })
})

function initAutocomplete(){
  var select = $('<select size="100px" name="question[tags]" id="question_tags" class="autocomplete_for_tags" ></select>')
  var tagInput = $('.autocomplete_for_tags');
  var width = tagInput.width();
  tagInput.after(select);
  if(typeof(tagInput)!='undefined' && $.trim(tagInput.val())!=''){
    var tags = tagInput.val().split(',')
    if( tags.length > 0){
      $.each(tags, function(i,n){
        if($.trim(n)!='')
        select.append('<option value="'+n+'" selected="selected" class="selected">'+n+'</option>')
      })
    }
  }
  tagInput.remove();
  $('.autocomplete_for_tags').fcbkcomplete({
    json_url: '/questions/tags_for_autocomplete.js',
    firstselected: true,
    delay: 200,
    maxitimes: 6,
    width: width
  });
}

function manageAjaxError(XMLHttpRequest, textStatus, errorThrown) {
  showMessage("sorry, something went wrong.", "error");
}

function showMessage(message, t, delay) {
  $("#notifyBar").remove();
  $.notifyBar({
    html: "<div class='message "+t+"' style='width: 100%; height: 100%; padding: 5px'>"+message+"</div>",
    delay: delay||3000,
    animationSpeed: "normal",
    barClass: "flash"
  });
}

function hasStorage(){
  if (window.localStorage && typeof(Storage)!='undefined'){
    return true;
  } else {
      return false;
  }
}

function initStorageMethods(){
  if(hasStorage()){
    Storage.prototype.setObject = function(key, value) {
        this.setItem(key, JSON.stringify(value));
    }

    Storage.prototype.getObject = function(key) {
        return JSON.parse(this.getItem(key));
    }
  }
}

function fillTextareas(){
   if(hasStorage() && localStorage[location.href]!=null && localStorage[location.href]!='null'){
       localStorageArr = localStorage.getObject(location.href);
       $.each(localStorageArr, function(i, n){
           $("#"+n.id).val(n.value);
           $("#"+n.id).parents('form.commentForm').show();
           $("#"+n.id).parents('form.nestedAnswerForm').show();
       })
    }
}

function addToLocalStorage(key, id, value){
  if(hasStorage()){
    var ls = localStorage[key];
    if($.trim(value)!=""){
      if(ls == null || ls == "null" || typeof(ls)=="undefined"){
          localStorage.setObject(key,[{id: id, value: value}]);
      } else {
          var storageArr = localStorage.getObject(key);
          var isIn = false;
          storageArr = $.map(storageArr, function(n, i){
              if(n.id == id){
                n.value = value;
                isIn = true;
              }
          return n;
        })
      if(!isIn)
        storageArr = $.merge(storageArr, [{id: id, value: value}]);
      localStorage.setObject(key, storageArr);
    }
    } else {removeFromLocalStorage(key, id);}
  }
}

function removeFromLocalStorage(key, id){
  if(hasStorage()){
    var ls = localStorage[key];
    if(typeof(ls)=='string'){
      var storageArr = localStorage.getObject(key);

      storageArr = $.map(storageArr, function(n, i){
          if(n.id == id){
            return null;
          } else {
              return n;
          }
      })
      localStorage.setObject(key, storageArr);
    }
  }
}


function sortValues(selectID, keepers){
  if(keepers){
    var any = $('#'+selectID+' option'+keepers);
    any.remove();
  }
  var sortedVals = $.makeArray($('#'+selectID+' option')).sort(function(a,b){
    return $(a).text() > $(b).text() ? 1: -1;
  });
  $('#'+selectID).empty().html(sortedVals);
  if(keepers)
    $('#'+selectID).prepend(any);
  //updateValueList();
};

function highlightEffect(object) {
  if(typeof object != "undefined") {
    object.fadeOut(400, function() {
      object.fadeIn(400)
    });
  }
}