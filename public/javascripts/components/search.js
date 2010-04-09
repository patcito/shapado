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
      settings.fields = $(this).find("input[type=text],textarea")
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

    live = function() {
      $.each(settings.fields, function(){
        $(this).keyup(function() {
        if((this.value.length > 0) && this.value != last) {
            if (timer) clearTimeout(timer);
            last = this.value;
            timer = setTimeout(query, settings.timeout);
          }
        });
      });
    }

    focusout = function() {
      $.each(settings.fields, function(){
        $(this).blur(function() {
          console.log("HERE")
          if((this.value.length > 0) && this.value != last) {
            query
          }
        });
      });
    }

    switch(settings.behaviour) {
      case "live":
        live()
        break;
      case "focusout":
        focusout();
        live();
        break;
    }
  }
})(jQuery);
