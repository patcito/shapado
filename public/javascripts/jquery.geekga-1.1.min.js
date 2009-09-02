/*
 * jquery.geekga.js - jQuery plugin for Google Analytics
 * 
 * Version 1.1
 * 
 * This plugin extends jQuery with two new functions:
 * 
 *   - $.geekGaTrackPage(account_id)
 *       Track a pageview.
 * 
 *   - $.geekGaTrackEvent(category, action, label, value)
 *       Track an event with a category, action, label and value.
 * 
 * 
 * This code is in the public domain.
 * 
 * Willem van Zyl
 * willem@geekology.co.za
 * http://www.geekology.co.za/blog/
 */

(function($){var pageTracker;$.geekGaTrackPage=function(account_id){var host=(("https:"==document.location.protocol)?"https://ssl.":"http://www.");var src=host+'google-analytics.com/ga.js';$.ajax({type:'GET',url:src,success:function(){pageTracker=_gat._getTracker(account_id);pageTracker._trackPageview();},error:function(){throw"Unable to load ga.js; _gat has not been defined.";},dataType:'script',cache:true});};
$.geekGaTrackEvent=function(category,action,label,value){if(typeof pageTracker!=undefined){pageTracker._trackEvent(category,action,label,value);}else{throw"Unable to track event; pageTracker has not been defined";}};})(jQuery);