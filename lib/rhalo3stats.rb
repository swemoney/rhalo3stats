# Rhalo3stats :: Halo 3 stats for Ruby on Rails

# You will need to install the hpricot gem before you can use this 
# plugin. Hopefully we won't need to scrape bungie.net in the near
# future, but for now they don't have RSS feeds or XML files for a 
# lot of the information.
require 'hpricot'
require 'open-uri'
require 'rss'

module Rhalo3stats
  
  module ModelExtensions
    
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def has_halo3_stats
        before_save   :cache_bungie_pages
        
        def escape_gamertag(gtag)
          gtag = gtag.downcase
          gtag.gsub!(/\s+/,'+')
          return gtag
        end
        
        include Rhalo3stats::ModelExtensions::InstanceMethods
      end
    end
    
    module InstanceMethods
      
      def bungie_net_front_page
        cache_bungie_pages if cache_expired?
        self.bnet_front
      end
      
      def bungie_net_ranked_stats_page
        cache_bungie_pages if cache_expired?
        self.bnet_ranked
      end
      
      def bungie_net_social_stats_page
        cache_bungie_pages if cache_expired?
        self.bnet_social
      end
      
      def halo3_basic_info
        get_basic_info
      end
      
      def halo3_ranked_stats
        get_career_stats
      end
      
      def halo3_social_stats
        get_career_stats(true)
      end

      def halo3_recent_screenshots
        get_recent_screenshots
      end

      def halo3_recent_games
        get_recent_games
      end
      
      def halo3_multiplayer_stats
        ranked_stats = get_career_stats
        social_stats = get_career_stats(true)
        kills        = ranked_stats[:kills].to_i + social_stats[:kills].to_i
        deaths       = ranked_stats[:deaths].to_i + social_stats[:deaths].to_i
        kill2death   = kill_to_death_ratio(kills, deaths)
        {
          :ranked => ranked_stats,
          :social => social_stats,
          :total  => {:kills => kills, :deaths => deaths, :kill_to_death => kill2death}
        }
      end

      
          protected

      
      def cache_expired?
        return expire_cache_on < Time.now ? true : false
      end
      
      def cache_expires_in(time)
        self.expire_cache_on = time.from_now
      end
      
      def bungie_net_front_page_html
        get_page(bungie_net_front_page_url).inner_html
      end

      def bungie_net_ranked_html
        get_page(bungie_net_ranked_url).inner_html
      end

      def bungie_net_social_html
        get_page(bungie_net_social_url).inner_html
      end

      def bungie_net_recent_screenshots_rss
        get_rss("http://www.bungie.net/stats/halo3/PlayerScreenshotsRss.ashx?gamertag=#{gamertag}")
      end

      def bungie_net_recent_games_rss
        get_rss("http://www.bungie.net/stats/halo3rss.ashx?g=#{gamertag}")
      end
      
      def bungie_net_front_page_url
        "http://www.bungie.net/stats/Halo3/default.aspx?player=#{gamertag}"
      end
      
      def bungie_net_ranked_url
        "http://www.bungie.net/stats/halo3/CareerStats.aspx?player=#{gamertag}&social=false&map=0"
      end
      
      def bungie_net_social_url
        "http://www.bungie.net/stats/halo3/CareerStats.aspx?player=#{gamertag}&social=true&map=0"
      end
      
      
          private


      def cache_bungie_pages
        doc = get_page(bungie_net_front_page_url)
        raise "GamerTag Does Not Exist" if (doc/"div.main div:nth(1) div:nth(1) div:nth(0) div:nth(0) div:nth(2) div:nth(0) h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        self.bnet_front  = doc.inner_html
        self.bnet_ranked = bungie_net_ranked_html
        self.bnet_social = bungie_net_social_html
        cache_expires_in(6.hours)
        self.save unless self.new_record?
      end
      
      def get_basic_info
        doc = Hpricot(bungie_net_front_page)
        {
          :gamertag          => (doc/"ctl00_mainContent_identityStrip_divHeader ul:nth(0) li:nth(0) h3:nth(0)").inner_html,
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

      def get_career_stats(social = false)
        doc = social == false ? Hpricot(bungie_net_ranked_stats_page) : Hpricot(bungie_net_social_stats_page)
        kills      = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(0) td:nth(1)").inner_html
        deaths     = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(1) td:nth(1)").inner_html
        kill2death = kill_to_death_ratio(kills, deaths)
        return {:kills => kills, :deaths => deaths, :kill_to_death => kill2death}
      end

      def get_recent_screenshots
        screenshots, doc = [], bungie_net_recent_screenshots_rss
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

      def get_recent_games
        games, doc = [], bungie_net_recent_games_rss
        doc.items.each_with_index do |item, i|
          games[i] = {
            :title       => item.title,
            :date        => item.pubDate,
            :link        => item.link,
            :description => item.description
          }
        end
        return games
      end

      def kill_to_death_ratio(kills, deaths)
        difference = kills.to_i - deaths.to_i
        if difference > 0
          return "+#{difference}"
        else
          return "#{difference}"
        end
      end

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
      
      def debug_me(message = "")
        logger.info("\n===== DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG =====\n\n#{message}\n\n===== DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG =====\n\n")
      end

    end
  end
end