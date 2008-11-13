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
  
  MEDAL_IDS = {
    "ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 1,  # Steaktacular
    "ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 2,  # Linktacular
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 3,  # Kill From The Grave
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 4,  # Laser Kill
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 5,  # Grenade Stick
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl08_ctl00_pnlMedalDetails" => 6,  # Incineration
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 7,  # Killjoy
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 8,  # Assassin
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 9,  # Beat Down
    "ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 10, # Extermination
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 11, # Bull True
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 12, # Killing Spree
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 13, # Killing Frenzy
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 14, # Running Riot
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 15, # Rampage
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 16, # Untouchable
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 17, # Invincible
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 18, # Double Kill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 19, # Triple Kill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 20, # Overkill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 21, # Killtacular
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 22, # Killtrocity
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 23, # Killimanjaro
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl06_ctl00_pnlMedalDetails" => 24, # Killtastrophe
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails" => 25, # Killapocolypse
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl08_ctl00_pnlMedalDetails" => 26, # Killionaire
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 27, # Sniper Kill
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 28, # Sniper Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl06_ctl00_pnlMedalDetails" => 29, # Sharpshooter
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 30, # Shotgun Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 31, # Open Season
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 32, # Sword Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 33, # Slice N Dice
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails" => 34, # Splatter
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 35, # Splatter Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails" => 36, # Vehicular Manslauter
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 37, # Wheelman
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 38, # Highjacker
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 39, # Skyjacker
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 40, # Killed VIP
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 41, # Bomb Planted
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 42, # Killed Bomb Carrier
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 43, # Flag Score
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 44, # Killed Flag Carrier
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl06_ctl00_pnlMedalDetails" => 45, # Flag Kill
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails" => 46, # Hail to the King
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 47, # Oddball Kill
    "ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 48, # Perfection
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 49, # Killed Juggernaut
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl04_ctl00_pnlMedalDetails" => 50, # Juggernaut Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails" => 51, # Unstoppable
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails" => 52, # Last Man Standing
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails" => 53, # Infection Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl05_ctl00_pnlMedalDetails" => 54, # Mmmm Brains
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails" => 55, # Zombie Killing Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl06_ctl00_pnlMedalDetails" => 56  # Hells Janitor
  }
  
  class ServiceRecordNotFound < StandardError; end
  class MissingGamertag < StandardError; end
  class PlayerNotRanked < StandardError; end
  
  module ModelExtensions
    
    def self.included(recipient)
      recipient.extend(ClassMethods)
    end
    
    module ClassMethods
      def has_halo3_stats
        before_create :setup_new_gamertag
        after_create  :finish_new_gamertag_setup
        include Rhalo3stats::ModelExtensions::InstanceMethods
      end
    end
    
    module InstanceMethods
      
      # for backwards compatibility
      def total_kill_to_death
        kill_to_death_difference
      end

      def halo3_recent_games
        recent_games
      end

      def halo3_recent_screenshots
        recent_screenshots
      end
      # End backwards compatibility
      
      def total_sprees
        ranked_sprees.to_i + social_sprees.to_i
      end
      
      def total_double_kills
        ranked_double_kills.to_i + social_double_kills.to_i
      end
      
      def total_triple_kills
        ranked_triple_kills.to_i + social_triple_kills.to_i
      end
      
      def total_splatters
        ranked_splatters.to_i + social_splatters.to_i
      end
      
      def total_snipes
        ranked_snipes.to_i + social_snipes.to_i
      end
      
      def total_sticks
        ranked_sticks.to_i + social_sticks.to_i
      end
      
      def total_beatdowns
        ranked_beatdowns.to_i + social_beatdowns.to_i
      end
      
      def primary_armor_color
        ARMOR_COLORS[primary_armor_color_number]
      end
      
      def secondary_armor_color
        ARMOR_COLORS[secondary_armor_color_number]
      end
      
      def recent_screenshots
        fetch_screenshots
      end
      
      def recent_games
        fetch_games
      end
      
      def ranked_kill_to_death
        ranked_deaths < 1 ? 0 : (ranked_kills.to_f/ranked_deaths.to_f).round(3).to_d
      end
      
      def social_kill_to_death
        social_deaths < 1 ? 0 : (social_kills.to_f/social_deaths.to_f).round(3).to_d
      end
      
      def kill_to_death_difference
        difference = total_kills.to_i - total_deaths.to_i
        return "+#{difference}" if difference > 0
        "#{difference}"
      end
      
      def kill_to_death_ratio
        total_deaths < 1 ? 0 : (total_kills.to_f/total_deaths.to_f).round(3).to_d
      end
      
      def total_kills
        ranked_kills.to_i + social_kills.to_i
      end
      
      def total_deaths
        ranked_deaths.to_i + social_deaths.to_i
      end
      
      def win_percent
        matchmade_games < 1 ? 0 : ((total_exp.to_f/matchmade_games.to_f) * 100).to_d
      end
      
      def update_stats
        log_me "Updating #{name}..."
        front_page = get_page(bungie_net_front_page_url)
        career     = get_page(bungie_net_career_url)
        
        update_front_page_stats(front_page)
        update_ranked_stats(career)
        update_social_stats(career)
        
        update_weapon_stats(career)
        update_medals(career)
        
        self.save
        log_me "#{name} has been updated"
        return self
      end
      
      def ranked_medals(top = 56)
        Medal.find(:all, :conditions => ["playlist_type = ? AND gamertag_id = ? AND quantity > ?", 1, self.id, 0], :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      def social_medals(top = 56)
        Medal.find(:all, :conditions => ["playlist_type = ? AND gamertag_id = ? AND quantity > ?", 2, self.id, 0], :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      def medal(medal_name_id, playlist_type)
        Medal.find_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
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
      
      def bungie_net_career_url
        "http://www.bungie.net/stats/Halo3/CareerStats.aspx?player=#{name.escape_gamertag}"
      end
      
      def screenshot_url(size, ssid)
        "http://www.bungie.net/Stats/Halo3/Screenshot.ashx?size=#{size}&ssid=#{ssid}"
      end
      
      protected
      
      def setup_new_gamertag
        raise MissingGamertag, "No GamerTag was passed" if name_downcase.blank?
        log_me "Creating #{name}..."
        self.name  = name_downcase
        front_page = get_page(bungie_net_front_page_url)
        raise ServiceRecordNotFound, "No Service Record Found" if (front_page/"div.spotlight h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        update_front_page_stats(front_page)
        log_me "#{name} has been created"
      end
      
      def finish_new_gamertag_setup
        log_me "Finishing New GamerTag, #{name}..."
        career = get_page(bungie_net_career_url)
        update_ranked_stats(career)
        update_social_stats(career)
        update_weapon_stats(career)
        update_medals(career)
        self.save
        log_me "#{name} is done being created"
      end
      
      def update_front_page_stats(front_page)
        raise ServiceRecordNotFound, "No Service Record Found" if (front_page/"div.spotlight h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        self.name                 = (front_page/"div.service_record_header div:nth(1) ul li h3").inner_html.split(" - ")[0].strip
        self.service_tag          = (front_page/"div.service_record_header div:nth(1) ul li h3 span").inner_html
        self.class_rank           = (front_page/"#ctl00_mainContent_identityStrip_lblRank").inner_html.split(": ")[1] || "Not Ranked"
        self.emblem_url           = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_identityStrip_EmblemCtrl_imgEmblem').first[:src]}"
        self.player_image_url     = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_imgModel').first[:src]}"              rescue self.player_image_url = "http://#{RMT_HOST}/images/no_player_image.jpg"
        self.class_rank_image_url = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_identityStrip_imgRank').first[:src]}" rescue self.class_rank_image_url = "http://#{RMT_HOST}/images/no_class_rank.jpg"
        self.campaign_status      = (front_page/'#ctl00_mainContent_identityStrip_hypCPStats img:nth(0)').first[:alt]             rescue self.campaign_status = "No Campaign"
        self.high_skill           = (front_page/"#ctl00_mainContent_identityStrip_lblSkill").inner_html.gsub(/\,/,"").to_i
        self.total_exp            = (front_page/"#ctl00_mainContent_identityStrip_lblTotalRP").inner_html.gsub(/\,/,"").to_i
        self.next_rank            = (front_page/"#ctl00_mainContent_identityStrip_hypNextRank").inner_html
        self.baddies_killed       = (front_page/"div.profile_strip div.profile_body ul.data li:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.allies_lost          = (front_page/"div.profile_strip div.profile_body ul.data li:nth(3)").inner_html.gsub(/\,/,"").to_i
        self.total_games          = (front_page/"div.profile_strip div.profile_body div.mmData ul:nth(0) li.values").inner_html.gsub(/\,/,"").to_i
        self.matchmade_games      = (front_page/"div.profile_strip div.profile_body div.mmData ul:nth(1) li.values").inner_html.gsub(/\,/,"").to_i
        self.custom_games         = (front_page/"div.profile_strip div.profile_body div.mmData ul:nth(2) li.values").inner_html.gsub(/\,/,"").to_i
        self.campaign_missions    = (front_page/"div.profile_strip div.profile_body div.mmData ul:nth(3) li.values").inner_html.gsub(/\,/,"").to_i
        self.member_since         = (front_page/"div.spotlight div ").inner_html.split("&nbsp; | &nbsp;")[0].gsub("Player Since ", "").to_date
        self.last_played          = (front_page/"div.spotlight div ").inner_html.split("&nbsp; | &nbsp;")[1].gsub("Last Played ", "").to_date
      end
      
      def update_ranked_stats(career)
        self.ranked_kills         = (career/"div.statWrap table:nth(0) tr:nth(2) td:nth(1) p").inner_html.to_i
        self.ranked_deaths        = (career/"div.statWrap table:nth(0) tr:nth(4) td:nth(1) p").inner_html.to_i
        self.ranked_games         = (career/"div.statWrap table:nth(0) tr:nth(6) td:nth(1) p").inner_html.to_i
        self.ranked_sprees        = (career/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_double_kills  = (career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_triple_kills  = (career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_sticks        = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_splatters     = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_snipes        = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_beatdowns     = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
      end
      
      def update_social_stats(career)
        self.social_kills         = (career/"div.statWrap table:nth(1) tr:nth(2) td:nth(1) p").inner_html.to_i
        self.social_deaths        = (career/"div.statWrap table:nth(1) tr:nth(4) td:nth(1) p").inner_html.to_i
        self.social_games         = (career/"div.statWrap table:nth(1) tr:nth(6) td:nth(1) p").inner_html.to_i
        self.social_sprees        = (career/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_double_kills  = (career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_triple_kills  = (career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_sticks        = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_splatters     = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_snipes        = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_beatdowns     = (career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
      end
      
      def update_weapon_stats(career)
        weapons = fetch_weapons(career)
        weapons = weapons.sort {|a,b| b[1] <=> a[1]}
        5.times do |i|
          self["weapon#{i+1}_name"] = weapons[i][0][0] rescue "Not Enough Data"
          self["weapon#{i+1}_url"]  = weapons[i][0][1] rescue "http://www.bungie.net/images/halo3stats/weapons/unknown.gif"
          self["weapon#{i+1}_num"]  = weapons[i][1]    rescue 0
        end
      end
      
      def update_medals(career)
        medal_divs = career.search("div.medal_list_overlay") do |medal|
          create_or_update_medal(MEDAL_IDS[medal[:id]], 1, (medal/"div div:nth(2) div.number").inner_html.gsub(",","").to_i)
          create_or_update_medal(MEDAL_IDS[medal[:id]], 2, (medal/"div div:nth(3) div.number").inner_html.gsub(",","").to_i)
        end
      end
      
      def create_or_update_medal(medal_name_id, playlist_type, updated_quantity)
        medal = Medal.find_or_create_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
        medal.update_attribute(:quantity, updated_quantity || 0) unless updated_quantity.blank?
      end
      
      def fetch_weapons(doc)
        weapons = {}
        weapon_divs = doc.search("div.weapon_container")
        weapon_divs.each do |weapon|
          weapon_stats = weapon/"div.top"
          name  = (weapon_stats/"div.title").inner_html
          total = (weapon_stats/"div:nth(4) div.number").inner_html.gsub(",","").to_i
          image = "http://www.bungie.net#{(weapon_stats/"div.overlay_img img").first[:src]}"
          weapons[[name, image]] = total
        end
        return weapons
      end
      
      def fetch_screenshots
        screenshots, doc = [], get_xml(bungie_net_recent_screenshots_url)
        (doc/:item).each_with_index do |item, i|
          screenshots[i] = {
            :full_url    => (item/'halo3:full_size_image').inner_html,
            :medium_url  => (item/'halo3:medium_size_image').inner_html,
            :thumb_url   => (item/'media:thumbnail').first[:url],
            :viewer_url  => (item/'link').inner_html,
            :title       => (item/:title).inner_html,
            :description => (item/:description).inner_html,
            :date        => (item/:pubDate).inner_html.to_time,
            :ssid        => pull_ssid( (item/'link').inner_html )
          }
        end
        return screenshots
      end
      
      def fetch_games
        games, doc = [], get_xml(bungie_net_recent_games_url)
        (doc/:item).each_with_index do |item, i|
          games[i] = {
            :title       => (item/:title).inner_html,
            :date        => (item/:pubDate).inner_html.to_time,
            :link        => (item/'link').inner_html,
            :description => (item/:description).inner_html,
            :gameid      => pull_gameid((item/'link').inner_html)
          }
        end
        return games
      end
      
      def primary_armor_color_number
        self.player_image_url =~ /&p6=(.*?)&/
        return $1.to_i
      end
      
      def secondary_armor_color_number
        self.player_image_url =~ /&p7=(.*?)&/
        return $1.to_i
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
        url =~ /\?h3fileid\=(\d+)/
        return $1
      end
      
      def pull_gameid(url)
        url =~ /\?gameid=(\d+)\&/
        return $1
      end
      
      def log_me(message = "")
        logger.info("rHalo3Stats : INFO : #{message}")
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