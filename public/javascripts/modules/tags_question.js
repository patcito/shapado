$(document).ready(function() {
  $("#filter_tags").find("input[type=submit]").hide();
  $("#filter_tags").searcher({ url : "/questions/tags.js",
                              target : $("#tag_table"),
                              behaviour : "live",
                              timeout : 500,
                              extraParams : { 'format' : 'js' },
                              success: function(data) { $('#tags').hide() }
  });
});
