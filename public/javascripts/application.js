// Common JavaScript code across your application goes here.
// Theme

var Theme = {
  activate: function(name) {
    window.location.hash = 'themes/' + name
    Theme.loadCurrent();
  },

  loadCurrent: function() {
    var hash = window.location.hash;
    if (hash.length > 0) {
      matches = hash.match(/^#themes\/([a-z0-9\-_]+)$/);
      if (matches && matches.length > 1) {
        $('#current-theme').attr('href', '/stylesheets/themes/' + matches[1] + '/style.css');
      } else {
        alert('theme not valid');
      }
    }
  }
}

$(document).ready(function() {
  Theme.loadCurrent();
  $.localScroll();
  $('.table :checkbox.toggle').each(function(i, toggle) {
    $(toggle).change(function(e) {
      $(toggle).parents('table:first').find(':checkbox:not(.toggle)').each(function(j, checkbox) {
        checkbox.checked = !checkbox.checked;
  })
    });
  });
});

$.postJSON = function(url, data, callback) {
  if(data && data.length > 0)
    data += "&format=json"
  else
    data = "format=json"
  $.post(url, data, callback, "json");
};

function renderFlashMessage(message) {
  $('#flash-messages').html(message);
}

//


