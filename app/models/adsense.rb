class Adsense < Ad

  key :google_ad_client, String
  key :google_ad_slot, Integer
  key :google_ad_width, Integer
  key :google_ad_height, Integer

  validates_presence_of     :google_ad_client
  validates_presence_of     :google_ad_slot
  validates_presence_of     :google_ad_width
  validates_presence_of     :google_ad_height

  def ad
    return "<script type=\"text/javascript\"><!--
        google_ad_client = \"#{google_ad_client}\";
        google_ad_slot = \"#{google_ad_slot}\";
        google_ad_width = #{google_ad_width};
        google_ad_height = #{google_ad_height};
        //-->
        </script>
        <script type=\"text/javascript\"
        src=\"http://pagead2.googlesyndication.com/pagead/show_ads.js\">
        </script>"
  end

end
