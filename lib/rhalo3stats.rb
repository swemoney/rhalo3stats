# Rhalo3stats :: Halo 3 stats for Ruby on Rails

# You will need to install the hpricot gem before you can use this 
# plugin. Hopefully we won't need to scrape bungie.net in the near
# future, but for now they don't have RSS feeds or XML files for a 
# lot of the information.
require 'hpricot'
require 'open-uri'
require 'rss'

module Rhalo3stats
  
  class ServiceRecordNotFound < StandardError; end
  class MissingGamertag < StandardError; end
  
  module ModelExtensions
    
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def has_halo3_stats
        before_create :setup_new_gamertag
        include Rhalo3stats::ModelExtensions::InstanceMethods
      end
    end
    
    module InstanceMethods

      def halo3_recent_screenshots
        get_recent_screenshots
      end

      def halo3_recent_games
        get_recent_games
      end
      
      def ranked_kill_to_death
        kill_to_death_ratio(ranked_kills, ranked_deaths)
      end
      
      def social_kill_to_death
        kill_to_death_ratio(social_kills, social_deaths)
      end
      
      def total_kills
        ranked_kills + social_kills
      end
      
      def total_deaths
        ranked_deaths + social_deaths
      end
      
      def total_kill_to_death
        difference = total_kills.to_i - total_deaths.to_i
        return "+#{difference}" if difference > 0
        return "#{difference}"
      end

      def kill_to_death_ratio
        (total_kills.to_f/total_deaths.to_f).round(2)
      end
      
      def win_percent
        ((total_exp.to_f/matchmade_games.to_f)*100)
      end
      
      def update_stats
        if updated_at < 2.hours.ago
          refresh_information
          return true
        else
          return false
        end
      end      
          
          
          protected
          
          
      def setup_new_gamertag
        raise MissingGamertag, "No GamerTag was passed" if name_downcase.blank?
        self.name = name_downcase
        debug_me("Setting Up New Gamertag: #{name}...")
        front = get_page(bungie_net_front_page_url)
        raise ServiceRecordNotFound, "No Service Record Found" if (front/"div.main div:nth(1) div:nth(1) div:nth(0) div:nth(0) div:nth(2) div:nth(0) h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        save_front_page_information(front)
        save_career_stats
        debug_me("Finished Setting Up #{name}... Saving Record.")
      end
      
      def refresh_information
        front = get_page(bungie_net_front_page_url)
        save_front_page_information(front)
        save_career_stats
        self.save
      end
      
      def bungie_net_recent_screenshots_url
        "http://www.bungie.net/stats/halo3/PlayerScreenshotsRss.ashx?gamertag=#{name.escape_gamertag}"
      end

      def bungie_net_recent_games_url
        "http://www.bungie.net/stats/halo3rss.ashx?g=#{name.escape_gamertag}&md=3"
      end
      
      def bungie_net_front_page_url
        "http://www.bungie.net/stats/Halo3/default.aspx?player=#{name.escape_gamertag}"
      end
      
      def bungie_net_ranked_url
        "http://www.bungie.net/stats/halo3/CareerStats.aspx?player=#{name.escape_gamertag}&social=false&map=0"
      end
      
      def bungie_net_social_url
        "http://www.bungie.net/stats/halo3/CareerStats.aspx?player=#{name.escape_gamertag}&social=true&map=0"
      end
      
      def screenshot_url(size, ssid)
        "http://www.bungie.net/Stats/Halo3/Screenshot.ashx?size=#{size}&ssid=#{ssid}"
      end
      
      def save_front_page_information(doc)
        self.name                 = (doc/"#ctl00_mainContent_identityStrip_divHeader ul:nth(0) li:nth(0) h3:nth(0)").inner_html.gsub!(/\s+-\s<span.+span>/,"")
        self.service_tag          = (doc/"#ctl00_mainContent_identityStrip_lblServiceTag").inner_html
        self.class_rank           = (doc/"#ctl00_mainContent_identityStrip_lblRank").inner_html
        self.emblem_url           = "http://www.bungie.net#{(doc/'#ctl00_mainContent_identityStrip_EmblemCtrl_imgEmblem').first[:src]}"
        self.player_image_url     = "http://www.bungie.net#{(doc/'#ctl00_mainContent_imgModel').first[:src]}"
        self.class_rank_image_url = "http://www.bungie.net#{(doc/'#ctl00_mainContent_identityStrip_imgRank').first[:src]}"
        self.campaign_status      = (doc/'#ctl00_mainContent_identityStrip_hypCPStats img:nth(0)').first[:alt]
        self.high_skill           = (doc/"#ctl00_mainContent_identityStrip_lblSkill").inner_html.gsub(/\,/,"").to_i
        self.total_exp            = (doc/"#ctl00_mainContent_identityStrip_lblTotalRP").inner_html.gsub(/\,/,"").to_i
        self.next_rank            = (doc/"#ctl00_mainContent_identityStrip_hypNextRank").inner_html
        self.baddies_killed       = (doc/"div.profile_strip div:nth(1) table:nth(1) tr:nth(1) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.allies_lost          = (doc/"div.profile_strip div:nth(1) table:nth(1) tr:nth(2) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.total_games          = (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(0) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.matchmade_games      = (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(1) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.custom_games         = (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(2) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.campaign_missions    = (doc/"div.profile_strip div:nth(1) table:nth(0) tr:nth(3) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.member_since         = (doc/"div.profile_strip div:nth(1) ul:nth(0) li:nth(1)").inner_html.to_date
        self.last_played          = (doc/"div.profile_strip div:nth(1) ul:nth(0) li:nth(4)").inner_html.to_date
      end
      
      def save_career_stats
        ranked = get_page(bungie_net_ranked_url)
        social = get_page(bungie_net_social_url)
        save_ranked_stats(ranked)
        save_social_stats(social)
      end
      
      def save_ranked_stats(doc)
        self.ranked_kills  = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(0) td:nth(1)").inner_html.to_i
        self.ranked_deaths = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(1) td:nth(1)").inner_html.to_i
      end
      
      def save_social_stats(doc)
        self.social_kills  = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(0) td:nth(1)").inner_html.to_i
        self.social_deaths = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) table:nth(0) tr:nth(1) td:nth(1)").inner_html.to_i
      end

      def get_recent_screenshots
        screenshots, doc = [], get_xml(bungie_net_recent_screenshots_url)
        (doc/:item).each_with_index do |item, i|
          screenshots[i] = {
            :full_url    => (item/'halo3:full_size_image').inner_html,
            :medium_url  => (item/'halo3:medium_size_image').inner_html,
            :thumb_url   => (item/'halo3:thumbnail_image').inner_html,
            :viewer_url  => (item/'link').inner_html,
            :title       => (item/:title).inner_html,
            :description => (item/:description).inner_html,
            :date        => (item/:pubDate).inner_html.to_time
          }
        end
        return screenshots
      end

      def get_recent_games
        games, doc = [], get_xml(bungie_net_recent_games_url)
        (doc/:item).each_with_index do |item, i|
          games[i] = {
            :title       => (item/:title).inner_html,
            :date        => (item/:pubDate).inner_html.to_time,
            :link        => (item/'link').inner_html,
            :description => (item/:description).inner_html
          }
        end
        return games
      end
      
      def get_page(url)
        Hpricot.buffer_size = 262144
        Hpricot(open(url))
      end
      
      def get_xml(url)
        Hpricot.buffer_size = 262144
        Hpricot.XML(open(url))
      end

      def pull_ssid(url)
        url =~ /\?ssid\=(\d+)\&/
        return $1
      end
      
      def debug_me(message = "")
        logger.info("\n===== DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG =====\n\n#{message}\n\n===== DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG =====\n\n")
      end

    end
  end
end

class String
  def escape_gamertag
    tag = self.downcase
    tag.gsub!(/\s+$/,'')
    tag.gsub!(/\s+/,'+')
    return tag
  end
end