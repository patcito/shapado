$(document).ready(function() {
  $('#groups_slug').autocomplete('/groups/autocomplete_for_group_slug', {
      multiple: false,
      dataType: 'json',
      delay: 200,
      selectFirst: false,
      parse: function(data) {
          return $.map(data, function(item) {
              return {
                  data: item,
                  value: item.slug,
                  result: item.slug
              };
          });
      },
      formatItem: function(item) {
          return item.slug;
      }
  });
});
