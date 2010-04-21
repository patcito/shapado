$(document).ready(function() {
  $('.auto-link').autoVideo();
  setupEditor();
  setupWysiwygEditor();
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
  $(".markdown code").addClass("prettyprint")

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
            window.location="/users/login"
          }
        }
        btn.show();
      }, "json");
    }
    return false;
  });

  $("a#hide_announcement").click(function() {
    $("#announcement").hide();
    $.post($(this).attr("href"), "format=js");
    return false;
  });
})

function initAutocomplete(){
  $('.autocomplete_for_tags').autocomplete('/questions/tags_for_autocomplete.js', {
      multiple: true,
      delay: 200,
      max: 10,
      selectFirst: false,
      extraParams: {'format' : 'js'},
      formatResult: function(data, value) {
        return value.split(";")[0];
      },
      formatItem: function(data, i, n, value) {
        row = data[0].split(";")
        return row[0]+" "+row[1]
      }
  });
}

function manageAjaxError(XMLHttpRequest, textStatus, errorThrown) {
  showMessage("sorry, something went wrong.", "error");
}

$(window).load(function() {
  prettyPrint();
});

function showMessage(message, t) {
  $("#notifyBar").remove();
  $.notifyBar({
    html: "<div class='message "+t+"' style='width: 100%; height: 100%; padding: 5px'>"+message+"</div>",
    delay: 3000,
    animationSpeed: "normal",
    barClass: "flash"
  });
}

function highlightEffect(object) {
  if(typeof object != "undefined") {
    object.fadeOut(400, function() {
      object.fadeIn(400)
    });
  }
}

function setupWysiwygEditor() {
  var editor = $("#wysiwyg_editor");
  if(!editor || editor.length == 0)
    return;

  editor.wysiwyg();
}

function setupEditor() {
  var editor = $("#markdown_editor");
  if(!editor || editor.length == 0)
    return;

  var converter = new Showdown.converter;
  var timer_id = null;

  var converter_callback = function(value) {
    $('#markdown_preview')[0].innerHTML = converter.makeHtml(value);

    $('#markdown_preview.markdown p code').addClass("prettyprint");
    if(timer_id)
      clearTimeout(timer_id);

    timer_id = setTimeout(function(){
      prettyPrint();
    }, 500);

  }

  var textarea = editor.TextArea({
    change: converter_callback
  });

  var toolbar = $.Toolbar(textarea, {
    className: "markdown_toolbar"
  });

  //buttons
  toolbar.addButton('Italics',function(){
      this.wrapSelection('*','*');
  },{
    id: 'markdown_italics_button'
  });

  toolbar.addButton('Bold',function(){
      this.wrapSelection('**','**');
  },{
    id: 'markdown_bold_button'
  });

  toolbar.addButton('Link',function(){
    var selection = this.getSelection();
    var response = prompt('Enter Link URL','');
    if(response == null)
        return;
    this.replaceSelection('[' + (selection == '' ? 'Link Text' : selection) + '](' + (response == '' ? 'http://link_url/' : response).replace(/^(?!(f|ht)tps?:\/\/)/,'http://') + ')');
  },{
    id: 'markdown_link_button'
  });

  toolbar.addButton('Image',function(){
    var selection = this.getSelection();
    var response = prompt('Enter Image URL','');
    if(response == null)
        return;
    this.replaceSelection('![' + (selection == '' ? 'Image Alt Text' : selection) + '](' + (response == '' ? 'http://image_url/' : response).replace(/^(?!(f|ht)tps?:\/\/)/,'http://') + ')');
  },{
    id: 'markdown_image_button'
  });

  toolbar.addButton('Heading',function(){
    var selection = this.getSelection();
    if(selection == '')
        selection = 'Heading';
    this.replaceSelection('##'+selection+'##');
  },{
    id: 'markdown_heading_button'
  });

  toolbar.addButton('Unordered List',function(event){
    this.collectFromEachSelectedLine(function(line){
        return event.shiftKey ? (line.match(/^\*{2,}/) ? line.replace(/^\*/,'') : line.replace(/^\*\s/,'')) : (line.match(/\*+\s/) ? '*' : '* ') + line;
    });
  },{
    id: 'markdown_unordered_list_button'
  });

  toolbar.addButton('Ordered List',function(event){
    var i = 0;
    this.collectFromEachSelectedLine(function(line){
        if(!line.match(/^\s+$/)){
            ++i;
            return event.shiftKey ? line.replace(/^\d+\.\s/,'') : (line.match(/\d+\.\s/) ? '' : i + '. ') + line;
        }
    });
  },{
    id: 'markdown_ordered_list_button'
  });

  toolbar.addButton('Block Quote',function(event){
    this.collectFromEachSelectedLine(function(line){
        return event.shiftKey ? line.replace(/^\> /,'') : '> ' + line;
    });
  },{
    id: 'markdown_quote_button'
  });

  toolbar.addButton('Code Block',function(event){
    this.collectFromEachSelectedLine(function(line){
        return event.shiftKey ? line.replace(/    /,'') : '    ' + line;
    });
  },{
    id: 'markdown_code_button'
  });

  toolbar.addButton('Latex', function(event) {
    this.wrapSelection('$$','$$');
  }, {
    id: 'markdown_latex_button'
  });

  toolbar.addButton('Help',function(){
    window.open('http://daringfireball.net/projects/markdown/dingus');
  },{
    id: 'markdown_help_button'
  });

}
