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
        after_create :finish_new_gamertag_setup
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
      
      def primary_armor_color
        return ARMOR_COLORS[primary_armor_color_number]
      end
      
      def secondary_armor_color
        return ARMOR_COLORS[secondary_armor_color_number]
      end
      
      def recent_screenshots
        fetch_screenshots
      end
      
      def recent_games
        fetch_games
      end
      
      def ranked_kill_to_death
        (ranked_kills.to_f/ranked_deaths.to_f).round(2).to_d
      end
      
      def social_kill_to_death
        (social_kills.to_f/social_deaths.to_f).round(2).to_d
      end
      
      def kill_to_death_difference
        difference = total_kills.to_i - total_deaths.to_i
        return "+#{difference}" if difference > 0
        return "#{difference}"
      end
      
      def kill_to_death_ratio
        (total_kills.to_f/total_deaths.to_f).round(2).to_d
      end
      
      def total_kills
        ranked_kills + social_kills
      end
      
      def total_deaths
        ranked_deaths + social_deaths
      end
      
      def win_percent
        ((total_exp.to_f/matchmade_games.to_f) * 100).to_d
      end
      
      def update_stats
        log_me "Updating #{name}..."
        front_page = get_xml(bungie_net_front_page_url)
        ranked     = get_xml(bungie_net_ranked_url)
        social     = get_xml(bungie_net_social_url)
        
        update_front_page_stats(front_page)
        update_ranked_stats(ranked)
        update_social_stats(social)
        
        update_weapon_stats(ranked, social)
        update_ranked_medals(ranked)
        update_social_medals(social)
        
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
        return Medal.find_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
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
      
      protected
      
      def setup_new_gamertag
        raise MissingGamertag, "No GamerTag was passed" if name_downcase.blank?
        log_me "Creating #{name}..."
        self.name  = name_downcase
        front_page = get_page(bungie_net_front_page_url)
        raise ServiceRecordNotFound, "No Service Record Found" if (front_page/"div.main div:nth(1) div:nth(1) div:nth(0) div:nth(0) div:nth(2) div:nth(0) h1:nth(0)").inner_html == "Halo 3 Service Record Not Found"
        update_front_page_stats(front_page)
        log_me "#{name} has been created"
      end
      
      def finish_new_gamertag_setup
        log_me "Finishing New GamerTag, #{name}..."
        ranked     = get_page(bungie_net_ranked_url)
        social     = get_page(bungie_net_social_url)
        update_ranked_stats(ranked)
        update_social_stats(social)
        update_weapon_stats(ranked, social)
        update_ranked_medals(ranked)
        update_social_medals(social)
        self.save
        log_me "#{name} is done being created"
      end
      
      def update_front_page_stats(front_page)
        self.name                 = (front_page/"#ctl00_mainContent_identityStrip_divHeader ul:nth(0) li:nth(0) h3:nth(0)").inner_html.gsub!(/\s+-\s<span.+span>/,"")
        self.service_tag          = (front_page/"#ctl00_mainContent_identityStrip_lblServiceTag").inner_html
        self.class_rank           = (front_page/"#ctl00_mainContent_identityStrip_lblRank").inner_html
        self.emblem_url           = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_identityStrip_EmblemCtrl_imgEmblem').first[:src]}"
        self.player_image_url     = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_imgModel').first[:src]}"
        self.class_rank_image_url = "http://www.bungie.net#{(front_page/'#ctl00_mainContent_identityStrip_imgRank').first[:src]}"
        self.campaign_status      = (front_page/'#ctl00_mainContent_identityStrip_hypCPStats img:nth(0)').first[:alt] rescue self.campaign_status = "No Campaign"
        self.high_skill           = (front_page/"#ctl00_mainContent_identityStrip_lblSkill").inner_html.gsub(/\,/,"").to_i
        self.total_exp            = (front_page/"#ctl00_mainContent_identityStrip_lblTotalRP").inner_html.gsub(/\,/,"").to_i
        self.next_rank            = (front_page/"#ctl00_mainContent_identityStrip_hypNextRank").inner_html
        self.baddies_killed       = (front_page/"div.profile_strip div:nth(1) table:nth(1) tr:nth(1) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.allies_lost          = (front_page/"div.profile_strip div:nth(1) table:nth(1) tr:nth(2) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.total_games          = (front_page/"div.profile_strip div:nth(1) table:nth(0) tr:nth(0) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.matchmade_games      = (front_page/"div.profile_strip div:nth(1) table:nth(0) tr:nth(1) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.custom_games         = (front_page/"div.profile_strip div:nth(1) table:nth(0) tr:nth(2) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.campaign_missions    = (front_page/"div.profile_strip div:nth(1) table:nth(0) tr:nth(3) td:nth(1)").inner_html.gsub(/\,/,"").to_i
        self.member_since         = (front_page/"div.profile_strip div:nth(1) ul:nth(0) li:nth(1)").inner_html.to_date
        self.last_played          = (front_page/"div.profile_strip div:nth(1) ul:nth(0) li:nth(4)").inner_html.to_date
      end
      
      def update_ranked_stats(ranked)
        self.ranked_kills         = (ranked/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(1)").inner_html.to_i
        self.ranked_deaths        = (ranked/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(3)").inner_html.to_i
        self.ranked_games         = /\d+/.match((ranked/"div.header_bottom ul:nth(0) li:nth(0)").inner_html).to_s.to_i
        self.ranked_sprees        = (ranked/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
        self.ranked_double_kills  = (ranked/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
        self.ranked_triple_kills  = (ranked/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i
        self.ranked_sticks        = (ranked/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i
        self.ranked_splatters     = (ranked/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i
        self.ranked_snipes        = (ranked/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i
        self.ranked_beatdowns     = (ranked/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
      end
      
      def update_social_stats(social)
        self.social_kills         = (social/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(1)").inner_html.to_i
        self.social_deaths        = (social/"#ctl00_mainContent_pnlStatsContainer div:nth(0) div:nth(0) div:nth(0) ul:nth(0) li:nth(3)").inner_html.to_i
        self.social_games         = /\d+/.match((social/"div.header_bottom ul:nth(0) li:nth(0)").inner_html).to_s.to_i
        self.social_sprees        = (social/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
        self.social_double_kills  = (social/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
        self.social_triple_kills  = (social/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i
        self.social_sticks        = (social/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i
        self.social_splatters     = (social/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i
        self.social_snipes        = (social/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i
        self.social_beatdowns     = (social/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i
      end
      
      def update_weapon_stats(ranked, social)
        weapons = fetch_total_weapon_stats(ranked, social)
        weapons = weapons.sort {|a,b| b[1] <=> a[1]}
        5.times do |i|
          self["weapon#{i+1}_name"] = weapons[i][0][0]
          self["weapon#{i+1}_num"]  = weapons[i][1]
          self["weapon#{i+1}_url"]  = weapons[i][0][1]
        end
      end
      
      def update_ranked_medals(ranked)
        medals = fetch_medals(ranked)
        update_medals(medals, 1)
      end
      
      def update_social_medals(social)
        medals = fetch_medals(social)
        update_medals(medals, 2)
      end
      
      def fetch_medals(doc)
        medals = []
        medals[0]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Steaktacular
        medals[1]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Linktacular
        medals[2]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Kill From The Grave
        medals[3]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Laser Kill
        medals[4]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Grenade Stick
        medals[5]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i } # Incineration
        medals[6]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Killjoy
        medals[7]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Assassin
        medals[8]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Beat Down
        medals[9]  = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Extermination
        medals[10] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Bull True
        medals[11] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Killing Spree
        medals[12] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Killing Frenzy
        medals[13] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Running Riot
        medals[14] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Rampage
        medals[15] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl01_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Untouchable
        medals[16] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Invincible
        medals[17] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Double Kill
        medals[18] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Triple Kill
        medals[19] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Overkill
        medals[20] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Killtacular
        medals[21] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Killtrocity
        medals[22] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Killimanjaro
        medals[23] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Killtastrophe
        medals[24] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl03_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i } # Killapocolypse
        medals[25] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Killionaire
        medals[26] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Sniper Kill
        medals[27] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Sniper Spree
        medals[28] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Sharpshooter
        medals[29] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Shotgun Spree
        medals[30] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Open Season
        medals[31] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Sword Spree
        medals[32] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Slice N Dice
        medals[33] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Splatter
        medals[34] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Splatter Spree
        medals[35] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl02_rptPlayerMedals_ctl08_liOnOver div.num").inner_html.to_i } # Vehicular Manslauter
        medals[36] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Wheelman
        medals[37] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Highjacker
        medals[38] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl05_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Skyjacker
        medals[39] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Killed VIP
        medals[40] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Bomb Planted
        medals[41] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Killed Bomb Carrier
        medals[42] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Flag Score
        medals[43] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Killed Flag Carrier
        medals[44] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Flag Kill
        medals[45] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl08_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Hail to the King
        medals[46] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl04_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Oddball Kill
        medals[47] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl00_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Perfection
        medals[48] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Killed Juggernaut
        medals[49] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl04_liOnOver div.num").inner_html.to_i } # Juggernaut Spree
        medals[50] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl07_liOnOver div.num").inner_html.to_i } # Unstoppable
        medals[51] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl06_rptPlayerMedals_ctl01_liOnOver div.num").inner_html.to_i } # Last Man Standing
        medals[52] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl02_liOnOver div.num").inner_html.to_i } # Infection Spree
        medals[53] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl05_liOnOver div.num").inner_html.to_i } # Mmmm Brains
        medals[54] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl03_liOnOver div.num").inner_html.to_i } # Zombie Killing Spree
        medals[55] = { :quantity => (doc/"#ctl00_mainContent_rptMedalRow_ctl07_rptPlayerMedals_ctl06_liOnOver div.num").inner_html.to_i } # Hells Janitor
        return medals
      end
      
      def update_medals(medals, playlist_type)
        medals.each_with_index do |medal, i| 
          self.update_or_create_medal(i+1, playlist_type, medal[:quantity])
        end
      end
      
      def update_or_create_medal(medal_name_id, playlist_type, updated_quantity)
        medal = Medal.find_or_create_by_medal_name_id_and_playlist_type_and_gamertag_id(medal_name_id, playlist_type, self.id)
        medal.update_attribute(:quantity, updated_quantity || 0) unless updated_quantity.blank?
      end
      
      def fetch_total_weapon_stats(ranked, social)
        ranked_weapons = fetch_weapons(ranked)
        social_weapons = fetch_weapons(social)
        total_weapons  = combine_weapons(ranked_weapons, social_weapons)
        return total_weapons
      end
      
      def fetch_weapons(doc)
        weapons = {}
        weapon_ids = doc.inner_html.scan(/ctl00_mainContent_rptWeapons_ctl\d\d_pnlWeaponDetails/).uniq
        weapon_ids.each do |weapon_id|
          name  = (doc/"##{weapon_id} div.top div.message div.title").inner_html
          total = (doc/"##{weapon_id} div.total div.number").inner_html.to_i
          image = "http://www.bungie.net#{(doc/"##{weapon_id} div.top div.overlay_img img").first[:src]}"
          weapons[[name, image]] = total
        end
        return weapons
      end
      
      def combine_weapons(ranked_weapons, social_weapons)
        ranked_weapons.update(social_weapons) {|name, ranked_val, social_val| ranked_val + social_val}
        return ranked_weapons
      end
      
      def fetch_screenshots
        screenshots, doc = [], get_xml(bungie_net_recent_screenshots_url)
        (doc/:item).each_with_index do |item, i|
          screenshots[i] = {
            :full_url    => (item/'halo3:full_size_image').inner_html,
            :medium_url  => (item/'halo3:medium_size_image').inner_html,
            :thumb_url   => (item/'halo3:thumbnail_image').inner_html,
            :viewer_url  => (item/'link').inner_html,
            :title       => (item/:title).inner_html,
            :description => (item/:description).inner_html,
            :date        => (item/:pubDate).inner_html.to_time,
            :ssid        => pull_ssid((item/'link').inner_html)
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
        url =~ /\?ssid\=(\d+)\&/
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