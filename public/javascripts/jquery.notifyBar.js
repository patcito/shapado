/*
*  Notify Bar - jQuery plugin
*
*  Copyright (c) 2009 Dmitri Smirnov
*
*  Licensed under the MIT license:
*  http://www.opensource.org/licenses/mit-license.php
*
*  Version: 1.0.2
*
*  Project home:
*  http://www.dmitri.me/blog/notify-bar
*/

/**
 *  param object
 */
$.notifyBar = function(settings)
{
  var bar = {};
  this.shown = false;
  if( !settings) {
    settings = {};
  }
  this.html           = settings.html || "Your message here";
  this.delay          = settings.delay || 2500;
  this.animationSpeed = settings.animationSpeed || "normal";
  this.jqObject       = settings.jqObject;

  if( this.jqObject) {
    bar = this.jqObject;
  } else {
    bar = $("<div></div>")
                  //basic css rules
                  .attr("id", "notifyBar")
                  .css("width", "100%")
                  .css("position", "fixed")
                  .css("top", "0px")
                  .css("left", "0px")
                  .css("z-index", "32768")
                  //additional css rules, which you can modify as you wish.
                  .css("font-size", "18px")
                  .css("text-align", "center")
                  .css("font-family", "Arial, Helvetica, serif")
                  .css("height", "30px")
                  .css("border-bottom", "1px solid #bbb");
    if(!settings.barClass){
      bar.css("background-color", "#dfdfdf")
         .css("color", "#000")
    }
  }

  bar.addClass(settings.barClass)

  bar.html(this.html).hide();
  var id =  bar.attr("id");
  switch (this.animationSpeed) {
    case "slow":
      asTime = 600;
      break;
    case "normal":
      asTime = 400;
      break;
    case "fast":
      asTime = 200;
      break;
    default:
      asTime = this.animationSpeed;
  }
  $("body").prepend(bar);
  bar.slideDown(asTime);
  setTimeout("$('#" + id + "').slideUp(" + asTime +");", this.delay + asTime);
};
