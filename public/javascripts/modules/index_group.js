$(document).ready(function() {

  $("#filter_groups").find("input[type=submit]").hide();

  $("#filter_groups").searcher({ url : "/groups.js",
                              target : $("#groups"),
                              behaviour : "live",
                              timeout : 500,
                              extraParams : { 'format' : 'js' },
                              success: function(data) {
                                $('#additional_info .pagination').html(data.pagination)
                              }
  });
});
