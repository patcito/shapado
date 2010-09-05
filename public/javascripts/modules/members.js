$(document).ready(function() {
    $('#member_user_id').autocomplete('/users/autocomplete_for_user_login.json', {
            multiple: false,
            dataType: 'json',
            delay: 200,
            selectFirst: false,
            parse: function(data) {
                return $.map(data, function(item) {
                    return {
                        data: item,
                        value: item.login,
                        result: item.login
                    };
                });
            },
            formatItem: function(item) {
                return item.login;
            }
        });
})
