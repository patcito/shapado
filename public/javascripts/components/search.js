(function($){
  $.fn.searcher = function(options) {
    var defaults = { timeout: 500,
      threshold: 100,
      extraParams: {},
      url: "",
      target: $("body"),
      behaviour : "live",
      success: function(data) {}
    }

    var options =  $.extend(defaults, options);

     return this.each(function() {
       var timer = null;
       var last = ""
       var settings = options
       var self = $(this)
       var extraParams = []

       if(typeof settings.fields == "undefined") {
          settings.fields = $(this).find("input[type=text],textarea")
       }

       //HACK?
       for (var property in settings.extraParams) {
         extraParams.push({ name : property, value : settings.extraParams[property]})
       }

       var query = function() {
         $.ajax({
           url: settings.url,
           dataType: "json",
           type: "GET",
           data: $.merge(settings.fields.serializeArray(), extraParams),
           success: function(data) {
             settings.target.empty();
             settings.target.append(data.html);
             settings.success(data);
           }
         });
       }

       live = function() {
         $.each(settings.fields, function(){
           var timer = null
           $(this).keyup(function() {
             if(this.value != last) {
               if (timer){
                 clearTimeout(timer)
               }
               last = this.value;
               timer = setTimeout(query, settings.timeout);
             }
           });
         });
       }

      focusout = function() {
        $.each(settings.fields, function(){
          $(this).blur(function() {
            if(this.value != last) {
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
    });
  }
})(jQuery);
