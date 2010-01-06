$(document).ready(function() {
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
          $('#current-theme').attr('href', '/stylesheets/compiled/themes/' + matches[1] + '/style.css');
          $('#current-nav').attr('href', '/stylesheets/compiled/navigation/' + matches[1] + '.css');
        } else {
          alert('theme not valid');
        }
      }
    }
  }

  $("select.choose_theme").change(function() {
    Theme.activate($(this).val());
    return false;
  });
})
