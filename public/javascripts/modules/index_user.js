$(document).ready(function() {

  $("#filter_users").find("input[type=submit]").hide();

  $("#filter_users").searcher({ url : "/users.js",
                              target : $("#users"),
                              behaviour : "live",
                              timeout : 500,
                              extraParams : { 'format' : 'js' },
                              success: function(data) {
                                $('#additional_info .pagination').html(data.pagination)
                              }
  });
});
