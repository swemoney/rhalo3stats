# Rhalo3stats :: Halo 3 stats for Ruby on Rails

# You will need to install the hpricot gem before you can use this 
# plugin. Hopefully we won't need to scrape bungie.net in the near
# future, but for now they don't have RSS feeds or XML files for a 
# lot of the information.
require 'hpricot'
require 'open-uri'
require 'rss'

module Rhalo3stats
  
  ARMOR_COLORS = {
    0 =>  {:code => "#444444", :name => "Steel"},
    1 =>  {:code => "#bbbbbb", :name => "Silver"},
    2 =>  {:code => "#ffffff", :name => "White"},
    3 =>  {:code => "#ff0000", :name => "Red"},
    4 =>  {:code => "#d65959", :name => "Mauv"},
    5 =>  {:code => "#ffaaaa", :name => "Salmon"},
    6 =>  {:code => "#ff9300", :name => "Orange"},
    7 =>  {:code => "#ffbb5e", :name => "Coral"},
    8 =>  {:code => "#ffe8c9", :name => "Peach"},
    9 =>  {:code => "#d4ab0c", :name => "Gold"},
    10 => {:code => "#fff000", :name => "Yellow"},
    11 => {:code => "#fffaaa", :name => "Pale"},
    12 => {:code => "#068100", :name => "Sage"},
    13 => {:code => "#32cf2a", :name => "Green"},
    14 => {:code => "#adffa9", :name => "Olive"},
    15 => {:code => "#08b499", :name => "Teal"},
    16 => {:code => "#27ecef", :name => "Aqua"},
    17 => {:code => "#84fbff", :name => "Cyan"},
    18 => {:code => "#003bdf", :name => "Blue"},
    19 => {:code => "#3a81dd", :name => "Cobolt"},
    20 => {:code => "#9ec8ff", :name => "Sapphire"},
    21 => {:code => "#6300cd", :name => "Violet"},
    22 => {:code => "#a446f0", :name => "Orchid"},
    23 => {:code => "#d5aeff", :name => "Lavender"},
    24 => {:code => "#97002c", :name => "Crimson"},
    25 => {:code => "#ff336e", :name => "Rubine"},
    26 => {:code => "#ff8fb0", :name => "Pink"},
    27 => {:code => "#622103", :name => "Brown"},
    28 => {:code => "#d77243", :name => "Tan"},
    29 => {:code => "#d9a085", :name => "Khaki"}
  }
    
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
      
      def primary_armor_color
        return ARMOR_COLORS[primary_armor_color_number]
      end
  
      def secondary_armor_color
        return ARMOR_COLORS[secondary_armor_color_number]
      end
      
      def halo3_recent_screenshots
        get_recent_screenshots
      end

      def halo3_recent_games
        get_recent_games
      end
      
      def ranked_kill_to_death
        (ranked_kills.to_f/ranked_deaths.to_f).round(2).to_d
      end
      
      def social_kill_to_death
        (social_kills.to_f/social_deaths.to_f).round(2).to_d
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
        (total_kills.to_f/total_deaths.to_f).round(2).to_d
      end
      
      def win_percent
        ((total_exp.to_f/matchmade_games.to_f) * 100).to_d
      end
      
      def weapon_stats
        get_weapon_stats(get_page(bungie_net_ranked_url), get_page(bungie_net_social_url))
      end
      
      def update_stats
        debug_me("Updating Gamertag: #{name}...")
        refresh_information
        debug_me("Finished Updating Gamertag: #{name}")
        return self
      end
      
      def ranked_medals(top = 56)
        Medal.find(:all, :conditions => {:playlist_type => 1, :gamertag_id => self.id}, :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      def social_medals(top = 56)
        Medal.find(:all, :conditions => {:playlist_type => 2, :gamertag_id => self.id}, :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      def medal(medal_name_id, playlist_type, updated_quantity = nil)
        medal = Medal.find_or_create_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
        medal.update_attribute(:quantity, updated_quantity || 0) unless updated_quantity.blank?
      end
          
          protected
          
      
      def primary_armor_color_number
        self.player_image_url =~ /&p6=(.*?)&/
        return $1.to_i
      end
      
      def secondary_armor_color_number
        self.player_image_url =~ /&p7=(.*?)&/
        return $1.to_i
      end
      
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
        self.campaign_status      = (doc/'#ctl00_mainContent_identityStrip_hypCPStats img:nth(0)').first[:alt] rescue self.campaign_status = "No Campaign"
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
        ranked  = get_page(bungie_net_ranked_url)
        social  = get_page(bungie_net_social_url)
        weapons = get_weapon_stats(ranked, social)
        save_ranked_stats(ranked)
        save_social_stats(social)
        save_weapon_stats(weapons)
      end
      
      def save_ranked_stats(doc)
        games_string              = (doc/"div.header_bottom ul:nth(0) li:nth(0)").inner_html
        self.ranked_kills         = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(1)").inner_html.to_i
        self.ranked_deaths        = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(3)").inner_html.to_i
        self.ranked_games         = /\d+/.match((doc/"div.header_bottom ul:nth(0) li:nth(0)").inner_html).to_s.to_i
        save_medal_stats(doc, 1)
      end
      
      def save_social_stats(doc)
        self.social_kills         = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(1)").inner_html.to_i
        self.social_deaths        = (doc/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(3)").inner_html.to_i
        self.social_games         = /\d+/.match((doc/"div.header_bottom ul:nth(0) li:nth(0)").inner_html).to_s.to_i
        save_medal_stats(doc, 2)
      end
      
      def save_medal_stats(doc, type)
        self.medal(1,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Steaktacular
        self.medal(2,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Linktacular
        self.medal(3,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Death from the Grave
        self.medal(4,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Laser Kill
        self.medal(5,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Grenade Stick
        self.medal(6,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i) # Incineration
        self.medal(7,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Killjoy
        self.medal(8,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Assassin
        self.medal(9,  type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Beat Down
        self.medal(10, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Extermination
        self.medal(11, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Bull True
        self.medal(12, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Killing Spree
        self.medal(13, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Killing Frenzy
        self.medal(14, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Running Riot
        self.medal(15, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Rampage
        self.medal(16, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Untouchable
        self.medal(17, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Invincible
        self.medal(18, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Double Kill
        self.medal(19, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Triple Kill
        self.medal(20, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Overkill
        self.medal(21, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Killtacular
        self.medal(22, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Killtrocity
        self.medal(23, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Killimanjaro
        self.medal(24, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Killtastrophe
        self.medal(25, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i) # Killapocolypse
        self.medal(26, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Killionaire
        self.medal(27, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Sniper Kill
        self.medal(28, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Sniper Spree
        self.medal(29, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Sharpshooter
        self.medal(30, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Shotgun Spree
        self.medal(31, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Open Season
        self.medal(32, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Sword Spree
        self.medal(33, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Slice N Dice
        self.medal(34, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Splatter
        self.medal(35, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Splatter Spree
        self.medal(36, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i) # Vehicular Manslauter
        self.medal(37, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Wheelman
        self.medal(38, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Highjacker
        self.medal(39, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Skyjacker
        self.medal(40, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Killed VIP
        self.medal(41, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Bomb Planted
        self.medal(42, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Killed Bomb Carrier
        self.medal(43, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Flag Score
        self.medal(44, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Killed Flag Carrier
        self.medal(45, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Flag Kill
        self.medal(46, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Hail to the King
        self.medal(47, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Oddball Kill
        self.medal(48, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Perfection
        self.medal(49, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Killed Juggernaut
        self.medal(50, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i) # Juggernaut Spree
        self.medal(51, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i) # Unstoppable
        self.medal(52, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i) # Last Man Standing
        self.medal(53, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i) # Infection Spree
        self.medal(54, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i) # Mmmm Brains
        self.medal(55, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i) # Zombie Killing Spree
        self.medal(56, type, (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i) # Hells Janitor
      end
      
      def save_weapon_stats(weapons)
        weapons = weapons["total"].sort {|a,b| b[1] <=> a[1]}
        5.times do |i|
          self["weapon#{i+1}_name"] = weapons[i][0][0]
          self["weapon#{i+1}_num"]  = weapons[i][1]
          self["weapon#{i+1}_url"]  = weapons[i][0][1]
        end
      end
      
      def get_weapon_stats(ranked, social)
        ranked_weapon_ids = ranked.inner_html.scan(/ctl00_mainContent_rptWeapons_ctl\d\d_pnlWeaponDetails/).uniq
        social_weapon_ids = social.inner_html.scan(/ctl00_mainContent_rptWeapons_ctl\d\d_pnlWeaponDetails/).uniq
        ranked_weapons, social_weapons, total_stats = {}, {}, {}
        
        ranked_weapon_ids.each do |weapon_id|
          name  = (ranked/"##{weapon_id} div.top div.message div.title").inner_html
          total = (ranked/"##{weapon_id} div.total div.number").inner_html.to_i
          image = "http://www.bungie.net#{(ranked/"##{weapon_id} div.top div.overlay_img img").first[:src]}"
          ranked_weapons[[name, image]] = total
          total_stats[[name, image]] = total
        end
        
        social_weapon_ids.each do |weapon_id|
          name  = (social/"##{weapon_id} div.top div.message div.title").inner_html
          total = (social/"##{weapon_id} div.total div.number").inner_html.to_i
          image = "http://www.bungie.net#{(social/"##{weapon_id} div.top div.overlay_img img").first[:src]}"
          social_weapons[[name, image]] = total
        end
        
        total_stats.update(social_weapons) {|name, ranked_val, social_val| ranked_val + social_val}
        return {"ranked" => ranked_weapons, "social" => social_weapons, "total" => total_stats}
        
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
        Hpricot(open(url, {"User-Agent" => "Mozilla/5.0 Firefox/3.0b5"}))
      end
      
      def get_xml(url)
        Hpricot.buffer_size = 262144
        Hpricot.XML(open(url, {"User-Agent" => "Mozilla/5.0 Firefox/3.0b5"}))
      end

      def pull_ssid(url)
        url =~ /\?ssid\=(\d+)\&/
        return $1
      end
      
      def debug_me(message = "")
        logger.info("\n================================\n\n#{message}\n\n================================\n\n")
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