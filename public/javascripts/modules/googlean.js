var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));

try {
  var code = $("a.googlean").attr("href");
  var pageTracker = _gat._getTracker(code);
  pageTracker._trackPageview();
} catch(err) {}
