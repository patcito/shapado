$(document).ready(function() {
  setupEditor();
  if((navigator.userAgent.indexOf('Gecko')!=-1
    && navigator.userAgent.indexOf('like Gecko')==-1) ||
    navigator.userAgent.indexOf('WebKit')!=-1){
  $(".feedback").removeClass("feedback").addClass("feedbackjs");}
  $(".feedbackform").dialog({ title: "Feedback", autoOpen: false, modal: true, width:"420px" })
  $('.cancel-feedback').click(function(){
    $(".feedbackform").dialog('close');
    return false;
  })
  $('#feedback').click(function(){
    var isOpen = $(".feedbackform").dialog('isOpen');
    if (isOpen){
      $(".feedbackform").dialog('close');
    } else {
      $(".feedbackform").dialog('open');
    }
    return false;
  })
  $(".markdown p code").addClass("prettyprint")
})

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

function setupEditor() {
  var converter = new Showdown.converter;
  var converter_callback = function(value) {
    $('#markdown_preview')[0].innerHTML = converter.makeHtml(value);
  }

  var textarea = $("#markdown_editor").TextArea({
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

  toolbar.addButton('Help',function(){
    window.open('http://daringfireball.net/projects/markdown/dingus');
  },{
    id: 'markdown_help_button'
  });

// make dropdown work with IE http://htmldog.com/articles/suckerfish/dropdowns/
  sfHover = function() {
    var sfEls = document.getElementById("nav").getElementsByTagName("LI");
    for (var i=0; i<sfEls.length; i++) {
      sfEls[i].onmouseover=function() {
        this.className+=" sfhover";
      }
      sfEls[i].onmouseout=function() {
        this.className=this.className.replace(new RegExp(" sfhover\\b"), "");
      }
    }
  }
  if (window.attachEvent) window.attachEvent("onload", sfHover);
}

