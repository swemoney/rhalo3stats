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
    "ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 1,  # Steaktacular
    "ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 2,  # Linktacular
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 3,  # Kill From The Grave
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 4,  # Laser Kill
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 5,  # Grenade Stick
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl08_ctl00_pnlMedal" => 6,  # Incineration
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 7,  # Killjoy
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 8,  # Assassin
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 9,  # Beat Down
    "ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 10, # Extermination
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 11, # Bull True
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 12, # Killing Spree
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 13, # Killing Frenzy
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 14, # Running Riot
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 15, # Rampage
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 16, # Untouchable
    "ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 17, # Invincible
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 18, # Double Kill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 19, # Triple Kill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 20, # Overkill
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 21, # Killtacular
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 22, # Killtrocity
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 23, # Killimanjaro
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl06_ctl00_pnlMedal" => 24, # Killtastrophe
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl07_ctl00_pnlMedal" => 25, # Killapocolypse
    "ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl08_ctl00_pnlMedal" => 26, # Killionaire
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 27, # Sniper Kill
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 28, # Sniper Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl06_ctl00_pnlMedal" => 29, # Sharpshooter
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 30, # Shotgun Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 31, # Open Season
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 32, # Sword Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 33, # Slice N Dice
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedal" => 34, # Splatter
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 35, # Splatter Spree
    "ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl07_ctl00_pnlMedal" => 36, # Vehicular Manslauter
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 37, # Wheelman
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 38, # Highjacker
    "ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 39, # Skyjacker
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 40, # Killed VIP
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 41, # Bomb Planted
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 42, # Killed Bomb Carrier
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 43, # Flag Score
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 44, # Killed Flag Carrier
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl06_ctl00_pnlMedal" => 45, # Flag Kill
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl01_ctl00_pnlMedal" => 46, # Hail to the King
    "ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 47, # Oddball Kill
    "ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 48, # Perfection
    "ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 49, # Killed Juggernaut
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl04_ctl00_pnlMedal" => 50, # Juggernaut Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl07_ctl00_pnlMedal" => 51, # Unstoppable
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl00_ctl00_pnlMedal" => 52, # Last Man Standing
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl02_ctl00_pnlMedal" => 53, # Infection Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl05_ctl00_pnlMedal" => 54, # Mmmm Brains
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl03_ctl00_pnlMedal" => 55, # Zombie Killing Spree
    "ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl06_ctl00_pnlMedal" => 56  # Hells Janitor
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
      
      # for backwards compatibility.. I can probably remove these.
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
      
      ##
      # Various helper methods for returning Total stats (i.e ranked + social)
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
      
      def total_kills
        ranked_kills.to_i + social_kills.to_i
      end
      
      def total_deaths
        ranked_deaths.to_i + social_deaths.to_i
      end
      
      ##
      # Returns primary or secondary armor color.
      def primary_armor_color
        ARMOR_COLORS[primary_armor_color_number]
      end
      
      def secondary_armor_color
        ARMOR_COLORS[secondary_armor_color_number]
      end
      
      ##
      # returns a hash of recent screenshots fetched via the rss feed.
      def recent_screenshots
        fetch_screenshots
      end
      
      ##
      # returns a hash of most recent games fetched via the rss feed.
      def recent_games
        fetch_games
      end
      
      ##
      # Kill to Death ratio to the 3rd decimal point.
      def ranked_kill_to_death
        ranked_deaths < 1 ? 0 : (ranked_kills.to_f/ranked_deaths.to_f).round(3).to_d
      end
      
      def social_kill_to_death
        social_deaths < 1 ? 0 : (social_kills.to_f/social_deaths.to_f).round(3).to_d
      end
      
      ##
      # A + or - number that shows how many more or less kills a user has than deaths.
      def kill_to_death_difference
        difference = total_kills.to_i - total_deaths.to_i
        return "+#{difference}" if difference > 0
        "#{difference}"
      end
      
      ##
      # Total kill to death ratio (ranked + social)
      def kill_to_death_ratio
        total_deaths < 1 ? 0 : (total_kills.to_f/total_deaths.to_f).round(3).to_d
      end
      
      ##
      # % of EXP gained vs. total matchmade games played
      def win_percent
        matchmade_games < 1 ? 0 : ((total_exp.to_f/matchmade_games.to_f) * 100).to_d
      end
      
      ##
      # Do all the updating for a gamertag.
      def update_stats
        t = Time.now; log_me "GAMERTAG UPDATE :: #{name} :: STARTED"
        @front_page = get_page(bungie_net_front_page_url) if @front_page.blank?
        @career     = get_page(bungie_net_career_url)     if @career.blank?
        
        update_front_page_stats
        update_ranked_stats
        update_social_stats
        update_weapon_stats
        update_medals
        self.save
        
        @front_page, @career = nil, nil
        log_me "GAMERTAG UPDATE :: #{name} :: DONE! (#{Time.now - t}s)"
        return self
      end
      
      ##
      # Check if the gamertag has played since the last update. Returns true if they have.
      def has_played_since_last_update?
        @front_page = get_page(bungie_net_front_page_url)
        last_played = (@front_page/"div.spotlight div ").inner_html.split("&nbsp; | &nbsp;")[1].gsub("Last Played ", "").to_date
        return last_played > self.updated_at.to_date
      end
      
      ##
      # Returns ranked or social medals. Can specify a maximum. Only returns medals that are greater than 0.
      def ranked_medals(top = 56)
        Medal.find(:all, :conditions => ["playlist_type = ? AND gamertag_id = ? AND quantity > ?", 1, self.id, 0], :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      def social_medals(top = 56)
        Medal.find(:all, :conditions => ["playlist_type = ? AND gamertag_id = ? AND quantity > ?", 2, self.id, 0], :order => 'quantity DESC', :include => :medal_name, :limit => top)
      end
      
      ##
      # Returns a specific medal. Must specify the medal_name_id. playlist_type defaults to ranked.
      def medal(medal_name_id, playlist_type = 1)
        Medal.find_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
      end
      
      ##
      # shortcut methods for returning url strings for various pages from bungie.net
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
      
      ##
      # When settings up a new gamertag, we save time by checking for the existence of the gamertag
      # before creating it. This way we're not downloading the career AND front pages if the gamertag
      # doesn't even exist. Also, we need an before_create AND after_create callback because when we
      # fetch the medals, they need to be associated with a gamertag_id and that doesn't exist until
      # after it has been created.
      def setup_new_gamertag
        raise MissingGamertag, "No GamerTag was passed" if name_downcase.blank?
        log_me "GAMERTAG CREATE :: #{name_downcase} :: STARTED!"
        Gamertag.transaction do
          self.name  = name_downcase
          @front_page = get_page(bungie_net_front_page_url) if @front_page.blank?
          update_front_page_stats
        end
      end
      
      ##
      # Finish up the new gamertag by updating the career stats page and creating medals.
      def finish_new_gamertag_setup
        Gamertag.transaction do 
          @career = get_page(bungie_net_career_url) if @career.blank?
          update_ranked_stats
          update_social_stats
          update_weapon_stats
          update_medals
          self.save
        end
        @front_page, @career = nil, nil
        log_me "GAMERTAG CREATE :: #{name} :: DONE!"
      end
      
      ##
      # Update all the stats that are found on the front page of bungie.net
      def update_front_page_stats
        raise ServiceRecordNotFound, "No Service Record Found" if (@front_page/"div.spotlight h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        self.name                 = (@front_page/"div.service_record_header div:nth(1) ul li h3").inner_html.split(" - ")[0].strip
        self.service_tag          = (@front_page/"div.service_record_header div:nth(1) ul li h3 span").inner_html
        self.class_rank           = (@front_page/"#ctl00_mainContent_identityStrip_lblRank").inner_html.split(": ")[1] || "Not Ranked"
        self.emblem_url           = "http://www.bungie.net#{(@front_page/'#ctl00_mainContent_identityStrip_EmblemCtrl_imgEmblem').first[:src]}"
        self.player_image_url     = "http://www.bungie.net#{(@front_page/'#ctl00_mainContent_imgModel').first[:src]}"              rescue self.player_image_url = "http://#{RMT_HOST}/images/no_player_image.jpg"
        self.class_rank_image_url = "http://www.bungie.net#{(@front_page/'#ctl00_mainContent_identityStrip_imgRank').first[:src]}" rescue self.class_rank_image_url = "http://#{RMT_HOST}/images/no_class_rank.jpg"
        self.campaign_status      = (@front_page/'#ctl00_mainContent_identityStrip_hypCPStats img:nth(0)').first[:alt]             rescue self.campaign_status = "No Campaign"
        self.high_skill           = (@front_page/"#ctl00_mainContent_identityStrip_lblSkill").inner_html.gsub(/\,/,"").to_i
        self.total_exp            = (@front_page/"#ctl00_mainContent_identityStrip_lblTotalRP").inner_html.gsub(/\,/,"").to_i
        self.next_rank            = (@front_page/"#ctl00_mainContent_identityStrip_hypNextRank").inner_html
        self.baddies_killed       = (@front_page/"div.profile_strip div.profile_body ul.data li:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.allies_lost          = (@front_page/"div.profile_strip div.profile_body ul.data li:nth(3)").inner_html.gsub(/\,/,"").to_i
        self.total_games          = (@front_page/"div.profile_strip div.profile_body div.mmData ul:nth(0) li.values").inner_html.gsub(/\,/,"").to_i
        self.matchmade_games      = (@front_page/"div.profile_strip div.profile_body div.mmData ul:nth(1) li.values").inner_html.gsub(/\,/,"").to_i
        self.custom_games         = (@front_page/"div.profile_strip div.profile_body div.mmData ul:nth(2) li.values").inner_html.gsub(/\,/,"").to_i
        self.campaign_missions    = (@front_page/"div.profile_strip div.profile_body div.mmData ul:nth(3) li.values").inner_html.gsub(/\,/,"").to_i
        self.member_since         = (@front_page/"div.spotlight div ").inner_html.split("&nbsp; | &nbsp;")[0].gsub("Player Since ", "").to_date
        self.last_played          = (@front_page/"div.spotlight div ").inner_html.split("&nbsp; | &nbsp;")[1].gsub("Last Played ", "").to_date
      end
      
      ##
      # Update all the ranked stats from the career page
      def update_ranked_stats
        self.ranked_kills         = (@career/"div.statWrap table:nth(0) tr:nth(2) td:nth(1) p").inner_html.to_i
        self.ranked_deaths        = (@career/"div.statWrap table:nth(0) tr:nth(4) td:nth(1) p").inner_html.to_i
        self.ranked_games         = (@career/"div.statWrap table:nth(0) tr:nth(6) td:nth(1) p").inner_html.to_i
        self.ranked_sprees        = (@career/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_double_kills  = (@career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_triple_kills  = (@career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_sticks        = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_splatters     = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_snipes        = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
        self.ranked_beatdowns     = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(2) div.number").inner_html.gsub(",","").to_i
      end
      
      ##
      # Update all the social stats from the career page
      def update_social_stats
        self.social_kills         = (@career/"div.statWrap table:nth(1) tr:nth(2) td:nth(1) p").inner_html.to_i
        self.social_deaths        = (@career/"div.statWrap table:nth(1) tr:nth(4) td:nth(1) p").inner_html.to_i
        self.social_games         = (@career/"div.statWrap table:nth(1) tr:nth(6) td:nth(1) p").inner_html.to_i
        self.social_sprees        = (@career/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_double_kills  = (@career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_triple_kills  = (@career/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_sticks        = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_splatters     = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_snipes        = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
        self.social_beatdowns     = (@career/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl00_ctl00_pnlMedalDetails div div:nth(3) div.number").inner_html.gsub(",","").to_i
      end
      
      ##
      # Update the top 5 weapon stats
      def update_weapon_stats
        weapons = fetch_weapons(@career)
        weapons = weapons.sort {|a,b| b[1] <=> a[1]}
        5.times do |i|
          self["weapon#{i+1}_name"] = weapons[i][0][0] rescue "Not Enough Data"
          self["weapon#{i+1}_url"]  = weapons[i][0][1] rescue "http://www.bungie.net/images/halo3stats/weapons/unknown.gif"
          self["weapon#{i+1}_num"]  = weapons[i][1]    rescue 0
        end
      end
      
      ##
      # Fetch weapon information and create a hash to parse.
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
      
      ##
      # Fetch medal information and create a hash to parse
      def fetch_medals
        updated_medals = []
        medal_divs = @career.search("div.medalBlock")
        medal_divs.each do |div| 
          ranked = (div/"span.top").inner_html.gsub(",","").to_i
          social = (div/"span.bot").inner_html.gsub(",","").to_i
          name_id = MEDAL_IDS[div[:id]]
          updated_medals << { :medal_name_id => name_id, :playlist_type => 1, :gamertag_id => self.id, :quantity => ranked }
          updated_medals << { :medal_name_id => name_id, :playlist_type => 2, :gamertag_id => self.id, :quantity => social }
        end
        return updated_medals
      end
      
      ##
      # Update all medals. If a medal doesn't exist, we create it. This has been refactored to be MUCH,
      # MUCH, MUCH more efficient! We now do 1 select and update what we need to instead of a seperate
      # select statement for each medal.
      def update_medals
        Medal.transaction do
          updated_medals = fetch_medals
          existing_medals = {}
          
          self.medals.each { |medal| existing_medals[[medal.medal_name_id, medal.playlist_type]] = medal }
          
          updated_medals.each { |medal|
            if existing_medal = existing_medals[[ medal[:medal_name_id], medal[:playlist_type] ]]
              existing_medal.update_attribute(:quantity, medal[:quantity])
            else
              Medal.create({:medal_name_id => medal[:medal_name_id], :quantity => medal[:quantity], :gamertag_id => self.id, :playlist_type => medal[:playlist_type]})
            end
          }
          
        end
      end
      
      ##
      # Grab the screenshots rss feed and create a hash that's easier to read in ruby.
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
      
      ##
      # Grab the recent games rss feed and create a hash that's easier to read in ruby.
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
      
      ##
      # Determine the user's armor colors by parsing the player_image_url
      def primary_armor_color_number
        self.player_image_url =~ /&p6=(.*?)&/
        return $1.to_i
      end
      
      def secondary_armor_color_number
        self.player_image_url =~ /&p7=(.*?)&/
        return $1.to_i
      end
      
      ##
      # Shortcut method for using the Hpricot methods for fetching pages
      def get_page(url)
        Hpricot.buffer_size = 262144
        Hpricot(open(url, {"User-Agent" => "Mozilla/5.0 Firefox/3.0b5"}))
      end
      
      def get_xml(url)
        Hpricot.buffer_size = 262144
        Hpricot.XML(open(url, {"User-Agent" => "Mozilla/5.0 Firefox/3.0b5"}))
      end
      
      ##
      # Grabs the ssid for a screenshot (or any item in a halo 3 fileshare, i suppose)
      def pull_ssid(url)
        url =~ /\?h3fileid\=(\d+)/
        return $1
      end
      
      ##
      # Grabs the game id
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