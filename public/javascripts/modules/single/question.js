$(document).ready(function() {
  $("textarea").focus(function() {
    if(!window.onbeforeunload) {
      window.onbeforeunload = function() {return I18n.on_leave_page;};
    }
  });
})
