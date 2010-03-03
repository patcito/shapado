(function($) {
  $.fn.search = function(settings) {
    var timer = null;
    var last = ""
    settings = $.extend({}, {
      timeout: 500,
      threshold: 100,
      extraParams: {},
      url: "",
      target: $("body"),
      behaviour : "live"
    }, settings)

    if(typeof settings.fields == "undefined") {
      settings.fields = $(this).find("input[type=text]")
    }

    self = $(this)


    var extraParams = []

    //HACK?
    for (property in settings.extraParams) {
      extraParams.push({ name : property, value : settings.extraParams[property]})
    }

    query = function() {
      $.ajax({
        url: settings.url,
        dataType: "json",
        type: "GET",
        data: $.merge(self.serializeArray(), extraParams),
        success: function(data) {
          settings.target.empty();
          settings.target.append(data.html);
          if(settings.success)
            settings.success();
        }
      });
    }

    switch(settings.behaviour) {
      case "live":
        settings.fields.keyup(function() {
          if (this.value != last) {
            if (timer) clearTimeout(timer);
            last = this.value;
            timer = setTimeout(query, settings.timeout);
          }
        });
        break;
      case "focusout":
        settings.fields.blur(function() {
          if ((this.value.length > 0) && this.value != last) {
            if (timer) clearTimeout(timer);
            last = this.value;
            timer = setTimeout(query, settings.timeout);
          }
        });
        break;
    }
  }
})(jQuery);
