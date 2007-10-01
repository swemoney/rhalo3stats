# Rhalo3stats :: Halo 3 stats for Ruby on Rails
module Rhalo3stats
  # You will need to install the hpricot gem before you can use this 
  # plugin. Hopefully we won't need to scrape bungie.net in the near
  # future, but for now they don't have RSS feeds or XML files for a 
  # lot of the information.
  require 'hpricot'
  require 'open-uri'
  require 'rss'

  def halo3_basic_info(gamertag)
    return basic_info(gamertag)
  end
  
  def halo3_multiplayer_stats(gamertag)
    ranked_stats = career_stats(gamertag)
    social_stats = career_stats(gamertag, "true")
    kills        = ranked_stats[:kills].to_i + social_stats[:kills].to_i
    deaths       = ranked_stats[:deaths].to_i + social_stats[:deaths].to_i
    kill2death   = kill_to_death_ratio(kills, deaths)
    return {
      :ranked => ranked_stats,
      :social => social_stats,
      :total  => {:kills => kills, :deaths => deaths, :kill_to_death => kill2death}
    }
  end

  # halo3_ranked_stats and halo3_social_stats should ONLY be used if you will only 
  # need one or the other! Don't use one of these if you will be calling the other
  # one afterwards. If this is what you need, use halo3_multiplayer_stats instead!
  def halo3_ranked_stats(gamertag)
    return career_stats(gamertag)
  end

  # halo3_ranked_stats and halo3_social_stats should ONLY be used if you will only 
  # need one or the other! Don't use one of these if you will be calling the other
  # one afterwards. If this is what you need, use halo3_multiplayer_stats instead!
  def halo3_social_stats(gamertag)
    return career_stats(gamertag, "true")
  end
  
  def halo3_recent_screenshots(gamertag)
    return recent_screenshots(gamertag)
  end

  def halo3_recent_multiplayer_games(gamertag)
    # working on this
  end

  def halo3_recent_campaign_games(gamertag)
    #working on this
  end

      protected

  def career_stats(gamertag, social = "false")
    doc = get_page("http://www.bungie.net/stats/halo3/CareerStats.aspx?player=#{gamertag}&social=#{social}&map=0")
    kills      = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(0) td:nth(1)").inner_html
    deaths     = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(1) td:nth(1)").inner_html
    kill2death = kill_to_death_ratio(kills, deaths)
    return {:kills => kills, :deaths => deaths, :kill_to_death => kill2death}
  end

  def basic_info(gamertag)
    doc = get_page("http://www.bungie.net/stats/Halo3/default.aspx?player=#{gamertag}")
    {
      :gamertag          => gamertag,
      :service_tag       => (doc/"#ctl00_mainContent_identityStrip_lblServiceTag").inner_html,
      :class_rank        => (doc/"#ctl00_mainContent_identityStrip_lblRank").inner_html,
      :highest_skill     => (doc/"#ctl00_mainContent_identityStrip_lblSkill").inner_html,
      :total_exp         => (doc/"#ctl00_mainContent_identityStrip_lblTotalRP").inner_html,
      :next_rank         => (doc/"#ctl00_mainContent_identityStrip_hypNextRank").inner_html.to_i.to_s,
      :emblem_url        => "http://www.bungie.net#{(doc/'#ctl00_mainContent_identityStrip_EmblemCtrl_imgEmblem').first[:src]}",
      :player_image_url  => "http://www.bungie.net#{(doc/'#ctl00_mainContent_imgModel').first[:src]}",
      :rank_image_url    => "http://www.bungie.net#{(doc/'#ctl00_mainContent_identityStrip_imgRank').first[:src]}",
      :baddies_killed    => (doc/"div.profile_strip div:nth(1) table:nth(1) tr:nth(1) td:nth(1)").inner_html,
      :allies_lost       => (doc/"div.profile_strip div:nth(1) table:nth(1) tr:nth(2) td:nth(1)").inner_html,
      :total_games       => (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(0) td:nth(1)").inner_html,
      :matchmade_games   => (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(1) td:nth(1)").inner_html,
      :custom_games      => (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(2) td:nth(1)").inner_html,
      :campaign_missions => (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(3) td:nth(1)").inner_html
    }
  end
  
  def recent_screenshots(gamertag)
    screenshots, doc = [], get_rss("http://www.bungie.net/stats/halo3/PlayerScreenshotsRss.ashx?gamertag=#{gamertag}")
    logger.info("DEBUG :::: #{doc.items[0].inspect}")
    doc.items.each_with_index do |item, i|
      ssid = pull_ssid(item.link)
      screenshots[i] = {
        :thumb_url   => screenshot_url('thumbnail', ssid),
        :medium_url  => screenshot_url('medium', ssid),
        :full_url    => screenshot_url('full', ssid),
        :viewer_url  => item.link,
        :title       => item.title,
        :description => item.description,
        :date        => item.date
      }
    end
    return screenshots
  end

  def kill_to_death_ratio(kills, deaths)
    difference = kills.to_i - deaths.to_i
    if difference > 0
      return "+#{difference}"
    else
      return difference.to_s
    end
  end

      private

  def get_page(url)
    Hpricot.buffer_size = 262144
    Hpricot(open(url))
  end
  
  def get_rss(url)
    RSS::Parser.parse(open(url))
  end
  
  def pull_ssid(url)
    url =~ /\?ssid\=(\d+)\&/
    return $1
  end
  
  def screenshot_url(size, ssid)
    "http://www.bungie.net/Stats/Halo3/Screenshot.ashx?size=#{size}&ssid=#{ssid}"
  end
  
end