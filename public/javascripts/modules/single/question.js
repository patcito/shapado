$(document).ready(function() {
  $("textarea").focus(function() {
    if(!window.onbeforeunload) {
      window.onbeforeunload = function() {
        var filled = false;
        $('textarea').each(function(){
          if($.trim($(this).val())!=''){
            filled = true;
          }
        })
        if(filled) {return I18n.on_leave_page; }
        return null;
      }
    }
  });
})
