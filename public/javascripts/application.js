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
  sortValues('#group_language', 'option', ':last', 'text', null);
  sortValues('#language_filter', 'option',  ':lt(2)', 'text', null);
  sortValues('#user_language', 'option',  false, 'text', null);
  sortValues('#lang_opts', '.radio_option', false, 'attr', 'id');

  $('.langbox.jshide').hide();
  $('.show-more-lang').click(function(){
      $('.langbox.jshide').toggle();
      return false;
  })
})

function initAutocomplete(){
  var tagInput = $('.autocomplete_for_tags');
  tagInput.autoSuggest('/questions/tags_for_autocomplete.js', {
    queryParam: 'tag',
    formatList: function(data, elem){
      return elem.html(data.caption);
    },
    preFill: tagInput.val(),
    startText: '',
    emptyText: 'No Results',
    limitText: 'No More Selections Are Allowed'
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


function sortValues(selectID, child, keepers, method, arg){
  if(keepers){
    var any = $(selectID+' '+child+keepers);
    any.remove();
  }
  var sortedVals = $.makeArray($(selectID+' '+child)).sort(function(a,b){
    return $(a)[method](arg) > $(b)[method](arg) ? 1: -1;
  });
  $(selectID).empty().html(sortedVals);
  if(keepers)
    $(selectID).prepend(any);
  // needed for firefox:
  $(selectID).val($(selectID+' '+child+'[selected=selected]').val());
};

function highlightEffect(object) {
  if(typeof object != "undefined") {
    object.fadeOut(400, function() {
      object.fadeIn(400)
    });
  }
}
