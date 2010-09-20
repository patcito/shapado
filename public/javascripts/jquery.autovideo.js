(function($) {
  $.fn.autoVideo = function(){
      this.each(function(){
          var isInCode = $(this).parents('code').length;
          if(!isInCode){
            var url = new String($(this).attr('href'));
            var video = false;
            var playButton = '<img src="/images/play_button.png" class="play_button">';
            if (video = url.match(/http:\/\/www\.dailymotion\.com.*\/video\/(.+)_*/)){
                var thumb = $('<div class="thumb"><img src="http://www.dailymotion.com/thumbnail/160x120/video/'+video[1]+'" class="video_thumbnail"></div>').attr({ "data-video-provider":"dailymotion", "data-videoid": video[1]}).append(playButton);
                $(this).after(thumb);
                thumb.one("click", function(){showPlayer(thumb)});
                $(this).remove();
            } else if (video = url.match(/http:\/\/(www.)?youtube\.com\/watch\?v=([A-Za-z0-9._%-]*)(\&\S+)?/)){
                var thumb = $('<div class="thumb"><img src="http://i.ytimg.com/vi/'+video[2]+'/1.jpg" class="video_thumbnail"></div>').attr({ "data-video-provider":"youtube", "data-videoid": video[2]}).append(playButton);
          $(this).after(thumb);
                thumb.one("click", function(){showPlayer(thumb)});
                $(this).remove();
            } else if (video = url.match(/^(https?:\/\/[^\/]*metacafe.com\/)watch\/([\w-]+)\/([^\/]*)/i)){
                var thumb = $('<div class="thumb"><img src="http://www.metacafe.com/thumb/'+video[2]+'.jpg" class="video_thumbnail"></div>').attr({ "data-video-provider":"metacafe", "data-videoid": video[2]+'/'+video[3]}).append(playButton);
                $(this).after(thumb);
                thumb.one("click", function(){showPlayer(thumb)});
                $(this).remove();
            } else if (video = url.match(/http:\/\/(www.)?vimeo\.com\/([A-Za-z0-9._%-]*)((\?|#)\S+)?/)){
                var thisurl = this;
                $.getJSON('http://vimeo.com/api/oembed.json?url=http%3A//vimeo.com/'+video[2]+'&callback=?', function(data){
                    var thumb = $('<div class="thumb"><img src="'+data.thumbnail_url+'" class="video_thumbnail"></div>').attr({ "data-video-provider":"vimeo", "data-videoid": video[2], "data-html": data.html}).append(playButton);
                    $(thisurl).after(thumb);
                    thumb.one("click", function(){showPlayer(thumb)});
                    $(thisurl).remove();
                })

            } else if (video = url.match(/^(https?:\/\/[^\/]*blip.tv\/)file\/([\w-]+).*/i)){
                var thisurl = this;
                $.getJSON('http://blip.tv/file?id='+video[2]+'&skin=json&version=2&callback=?', function(data){
                    var thumb = $('<div class="thumb"><img src="'+data[0].thumbnailUrl+'" class="video_thumbnail"></div>').attr({ "data-video-provider":"bliptv", "data-videoid": video[2], "data-html": data[0].embedCode}).append(playButton);
                    $(thisurl).after(thumb);
                    thumb.one("click", function(){showPlayer(thumb)});
                    $(thisurl).remove();
                })

            } else if (video = url.match(/\w+(\w+\.flv)/)){
                var thisurl = this;
                var thumb = $('<div class="thumb"><img src="/images/video.png" class="video_thumbnail"></div>').attr({ "data-video-provider":"flv", "data-videoid": url}).append(playButton);
                $(thisurl).after(thumb);
                thumb.one("click", function(){showPlayer(thumb)});
                $(thisurl).remove();
            }
        }
      })

          function showPlayer(thumb){
              var videoid =  thumb.attr('data-videoid');
              var provider = thumb.attr('data-video-provider');
              switch(provider){
              case "metacafe":
                  thumb.html('<embed src="http://www.metacafe.com/fplayer/'+videoid+'.swf" width="400" height="345" wmode="transparent" pluginspage="http://www.macromedia.com/go/getflashplayer" type="application/x-shockwave-flash" allowFullScreen="true" allowScriptAccess="always" name="Metacafe_3930172"> </embed><br><font size = 1><a href="http://www.metacafe.com/watch/'+videoid+'/">Link to video</a> - <a href="http://www.metacafe.com/">The most popular videos are a click away</a></font>');
                  break;
              case "youtube":
                  thumb.html('<object width="425" height="344"><param name="movie" value="http://www.youtube.com/v/'+videoid+'&hl=en_US&fs=1"></param><param name="allowFullScreen" value="true"></param><param name="allowscriptaccess" value="always"></param><embed src="http://www.youtube.com/v/'+videoid+'&hl=en_US&fs=1&" type="application/x-shockwave-flash" allowscriptaccess="always" allowfullscreen="true" width="425" height="344"></embed></object>');
                  break;
              case "dailymotion":
                  videoid = videoid.split('_')[0]
                  thumb.html('<object width="480" height="365"><param name="movie" value="http://www.dailymotion.com/swf/x7rduv&related=0"></param><param name="allowFullScreen" value="true"></param><param name="allowScriptAccess" value="always"></param><embed src="http://www.dailymotion.com/swf/x7rduv&related=0" type="application/x-shockwave-flash" width="480" height="365" allowfullscreen="true" allowscriptaccess="always"></embed></object>');
                  break;
              case "vimeo":
                  thumb.html(thumb.attr('data-html'));
                  break;
              case "bliptv":
                  thumb.html(thumb.attr('data-html'));
                  break;
              case "flv":
                  thumb.html('<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="640" height="375" id="FlvPlayer" align="middle"><param name="allowScriptAccess" value="sameDomain" /><param name="allowFullScreen" value="true" /><param name="movie" value="http://flvplayer.com/free-flv-player/FlvPlayer.swf" /><param name="quality" value="high" /><param name="bgcolor" value="FFFFFF" /><param name="FlashVars" value="flvpFolderLocation=http://flvplayer.com/free-flv-player/flvplayer/&flvpVideoSource='+thumb.attr("data-videoid")+'&flvpWidth=640&flvpHeight=375&flvpInitVolume=50&flvpTurnOnCorners=true&flvpBgColor=FFFFFF"><embed src="http://flvplayer.com/free-flv-player/FlvPlayer.swf" flashvars="flvpFolderLocation=http://flvplayer.com/free-flv-player/flvplayer/&flvpVideoSource='+thumb.attr("data-videoid")+'&flvpWidth=640&flvpHeight=375&flvpInitVolume=50&flvpTurnOnCorners=true&flvpBgColor=FFFFFF" quality="high" bgcolor="FFFFFF" width="640" height="375" name="FlvPlayer" align="middle" allowScriptAccess="sameDomain" allowFullScreen="true" type="application/x-shockwave-flash" pluginspage="http://www.adobe.com/go/getflashplayer" /></object>');
                  break;
              }
          }
  }
})(jQuery);
