require 'rubygems'
require 'gosu'
require './input_functions'

SCREEN_WIDTH = 1280
SCREEN_HEIGHT = 720
SIDE_WIDTH = 162

class TextField < Gosu::TextInput
    FONT = Gosu::Font.new(20)
    WIDTH = 350
    LENGTH_LIMIT = 500
    PADDING = 5
  
    INACTIVE_COLOR  = 0xcc_666666
    ACTIVE_COLOR    = 0xcc_ff6666
    SELECTION_COLOR = 0xcc_0000ff
    CARET_COLOR     = 0xff_ffffff
  
    attr_reader :x, :y
  
    def initialize(window, x, y)
      # It's important to call the inherited constructor.
      super()
  
      @window, @x, @y, @text = window, x, y
  
      # Start with a self-explanatory text in each field.
      self.text = @text
    end
  
    # In this example, we use the filter method to prevent the user from entering a text that exceeds
    # the length limit. However, you can also use this to blacklist certain characters, etc.
    def filter new_text
      allowed_length = [LENGTH_LIMIT - text.length, 0].max
      new_text[0, allowed_length]
    end
  
    def draw(z)
      # Change the background colour if this is the currently selected text field.
      if @window.text_input == self
        color = ACTIVE_COLOR
      else
        color = INACTIVE_COLOR
      end
      Gosu.draw_rect x - PADDING, y - PADDING, WIDTH + 2 * PADDING, height + 2 * PADDING, color, z
  
      # Calculate the position of the caret and the selection start.
      pos_x = x + FONT.text_width(self.text[0...self.caret_pos])
      sel_x = x + FONT.text_width(self.text[0...self.selection_start])
      sel_w = pos_x - sel_x
  
      # Draw the selection background, if any. (If not, sel_x and pos_x will be
      # the same value, making this a no-op call.)
      Gosu.draw_rect sel_x, y, sel_w, height, SELECTION_COLOR, z
  
      # Draw the caret if this is the currently selected field.
      if @window.text_input == self
        Gosu.draw_line pos_x, y, CARET_COLOR, pos_x, y + height, CARET_COLOR, z
      end
  
      # Finally, draw the text itself!
      FONT.draw_text self.text, x, y, z
    end
  
    def height
      FONT.height
    end
  
    # Hit-test for selecting a text field with the mouse.
    def under_mouse?
      @window.mouse_x > x - PADDING and @window.mouse_x < x + WIDTH + PADDING and
        @window.mouse_y > y - PADDING and @window.mouse_y < y + height + PADDING
    end
  
    # Tries to move the caret to the position specifies by mouse_x
    def move_caret_to_mouse
      # Test character by character
      1.upto(self.text.length) do |i|
        if @window.mouse_x < x + FONT.text_width(text[0...i])
          self.caret_pos = self.selection_start = i - 1;
          return
        end
      end
      # Default case: user must have clicked the right edge
      self.caret_pos = self.selection_start = self.text.length
    end
  end

module ZOrder
    BACKGROUND, SIDE, PLAYER, UI = *0..3
end

module Genre
    POP, CLASSIC, JAZZ, ROCK = *1..4
end

$genre_names = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock']

class ArtWork
    attr_accessor :bmp
    def initialize (file)
        @bmp = Gosu::Image.new(file)
    end
end
 
class Track
    attr_accessor :name, :location
    def initialize (name, location)
        @name = name
        @location = location
    end
end

class Album
    attr_accessor :album_iD, :title, :artist, :artwork, :genre, :track
    def initialize (album_iD, title, artist, artwork, genre, track)
        @album_iD = album_iD
        @title = title
        @artist = artist
        @artwork = artwork
        @genre = genre
        @track = track
    end
end

class Song
   attr_accessor :song
   def initialize (file)
       @song = Gosu::Song.new(file)
   end
end

class Application < Gosu::Window
    def initialize
        super SCREEN_WIDTH, SCREEN_HEIGHT
        self.caption = "MUSIC APPROVAL"
        @user = :pick
        @option = 5
        @login_admin = :logout
        @admin_account_pwd = Array.new()
        @user_login_file = 'accounts/admin_account.txt'
        @user_ico = Gosu::Image.new('img/admin.png')
        @locs = [60,60]
        @font = Gosu::Font.new(25)
        @font_color = Gosu::Color::BLACK
        @play_button = Gosu::Image.new('img/play.png')
        @pause_button = Gosu::Image.new('img/pause.png')
        @info_button = Gosu::Image.new('img/info.png')
        @approved_button = Gosu::Image.new('img/tick.png')
        @denied_button = Gosu::Image.new('img/cross.png')
        @darkmode_ico = Gosu::Image.new('img/darkmode.png')
        @current_mode = :light
        @SIDE_COLOR = Gosu::Color.new(248,248,248,255)
        @BACKGROUND_COLOR = Gosu::Color.new(255,255,255,255)
        @album_id = nil
        @act_id = nil 
        @current_album_page = 0
        @page = 0
        @index_album = 0
        @albums_per_page = 10
        button_function
        @genre_submit = '1'
        @albums_location = 'txt/music_file.txt'
        @status = 'txt/approved.txt'
        @page_call = :not_available
        @approved_albums_array = Array.new()
        @current_albums_reivew = Array.new()
        @current_genre = Array.new()
        @text_fields = Array.new(5) {|index| TextField.new(self, 700, 300 + index * 50)}
        @login_detail = Array.new(1) {|index| TextField.new(self, 700, 300 + index * 50)}
    end

    def approved_albums_array
        @approved_albums_array
    end

    def button_function(opt=0)
        if opt == 'space'
            @song.pause
        end
    rescue RuntimeError
    end
           
    def load_album()
        def read_track (music_file)
            name = music_file.gets
            location = music_file.gets.chomp
            track = Track.new(name, location)
            return track
        end

        def read_album(music_file, i)
            album_iD = i
            title = music_file.gets.chomp
            artist = music_file.gets
            artwork = music_file.gets.chomp
            genre = music_file.gets.to_i
            track = read_track(music_file)
            album = Album.new(album_iD, title, artist, artwork, genre, track)
            return album
        end

        def read_albums(music_file)
            count = music_file.gets.to_i
            albums = Array.new()
            i = 0
            while i < count
                album = read_album(music_file, i+1)
                albums << album
                i+=1
            end
            return albums
        end
        music_file = File.new(@albums_location, "r")
        albums = read_albums(music_file)
        return albums
    end

    def draw_background()
        draw_quad(0,0, @SIDE_COLOR, 0, SCREEN_WIDTH, @SIDE_COLOR, SIDE_WIDTH, 0, @SIDE_COLOR, SIDE_WIDTH, SCREEN_WIDTH, @SIDE_COLOR, z = ZOrder::SIDE)
        draw_quad(0,0, @BACKGROUND_COLOR, 0, SCREEN_WIDTH, @BACKGROUND_COLOR, SCREEN_WIDTH, 0, @BACKGROUND_COLOR, SCREEN_WIDTH, SCREEN_HEIGHT, @BACKGROUND_COLOR, z = ZOrder::BACKGROUND)
    end

    def needs_cursor?
        true 
    end

    def draw_tracks_by_genre(albums,option)
        i = @index_album
        @x_pos = 220
        @y_pos = 50
        while i < albums.length && i < (@albums_per_page*(@page+1))
            if albums[i].genre.to_i == option
                @bmp = Gosu::Image.new(albums[i].artwork)
                @bmp.draw(@x_pos, @y_pos, z = ZOrder::PLAYER, 0.1, 0.1)
                @font.draw("#{albums[i].track.name}", @x_pos+70, @y_pos+5, ZOrder::UI, 0.7, 0.7, @font_color)
                @font.draw("#{albums[i].artist}", @x_pos+70, @y_pos+25, ZOrder::UI, 0.7, 0.7, Gosu::Color::GRAY)
            end
            i+=1
            @y_pos += 60
            draw_button() 
        end
    end

    def draw_tracks(albums)
        i = @index_album
        @x_pos = 220
        @y_pos = 50
        while i < albums.length && i < (@albums_per_page*(@page+1))
            @bmp = Gosu::Image.new(albums[i].artwork)
            @bmp.draw(@x_pos, @y_pos, z = ZOrder::PLAYER, 0.1, 0.1)
            @font.draw("#{albums[i].track.name}", @x_pos+70, @y_pos+5, ZOrder::UI, 0.7, 0.7, @font_color)
            @font.draw("#{albums[i].artist}", @x_pos+70, @y_pos+25, ZOrder::UI, 0.7, 0.7, Gosu::Color::GRAY)
            i+=1
            @y_pos += 60
            draw_button() 
        end
    end

    def pause_changing_pg()
        if @song
            if @song.playing?
                @song.pause
            end
        end
    end

    def mode_dn()
        case @current_mode
        when :light
            @SIDE_COLOR = Gosu::Color.new(27,2,102)
            @BACKGROUND_COLOR = Gosu::Color.new(18,6,56)
            @font_color = Gosu::Color::WHITE
            @play_button = Gosu::Image.new('img/play_light.png')
            @pause_button = Gosu::Image.new('img/pause.png')
            @info_button = Gosu::Image.new('img/info_light.png')
            @approved_button = Gosu::Image.new('img/tick.png')
            @denied_button = Gosu::Image.new('img/cross.png')
            @darkmode_ico = Gosu::Image.new('img/darkmode_light.png')
            @current_mode = :dark
        when :dark
            @SIDE_COLOR = Gosu::Color.new(248,248,248,255)
            @BACKGROUND_COLOR = Gosu::Color.new(255,255,255,255)
            @font_color = Gosu::Color::BLACK
            @play_button = Gosu::Image.new('img/play.png')
            @pause_button = Gosu::Image.new('img/pause.png')
            @info_button = Gosu::Image.new('img/info.png')
            @approved_button = Gosu::Image.new('img/tick.png')
            @denied_button = Gosu::Image.new('img/cross.png')
            @darkmode_ico = Gosu::Image.new('img/darkmode.png')
            @current_mode = :light
        end
    end

    def log_out()
        @current_mode = :dark
        mode_dn()
        @user = :pick
        @login_admin = :logout
    end
    
    def submit_push()
        list = @current_albums_reivew
        i = 0
        @current_albums_reivew.push @text_fields[0].text
        @current_albums_reivew.push @text_fields[1].text
        @current_albums_reivew.push @text_fields[2].text
        @current_albums_reivew.push @genre_submit
        @current_albums_reivew.push @text_fields[3].text
        @current_albums_reivew.push @text_fields[4].text
    end

    def submit_gets()
        rfile = File.new(@albums_location,'r')
        list = @current_albums_reivew
        size = rfile.gets.to_i
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets
            track_name = rfile.gets
            track_location = rfile.gets
            list.push title
            list.push artist
            list.push cover
            list.push genre
            list.push track_name
            list.push track_location
        end
        rfile.close
    end

    def submit_write()
        wfile = File.new(@albums_location,'w') #@albums_location
        wfile.puts @current_albums_reivew.size/6
        @current_albums_reivew.each do |element|
            wfile.puts element
        end
        wfile.close
    end

    def pwd_push()
        rfile = File.new(@user_login_file,'r')
        admin_pwd = @admin_account_pwd
        size = rfile.gets.to_i
        for i in 0..(size-1)
            pwd = rfile.gets
            @admin_account_pwd.push pwd
        end
        rfile.close
    end

    def pwd_checking()
        admin_pwd = @admin_account_pwd
        input_pwd = @login_detail[0].text
        if admin_pwd.include?(input_pwd.to_s)
            @login_admin = :login
        end
    end

    def master(albums)
        @current_genre = Array.new()
        current_albums_genre()
        reverse_gerne_music_file_arr()
        reverse_write()
        @current_genre = Array.new()
        reset() #Clear File
        save_current_review(albums) #save current review to array
        write_to_sort_genre() #array to file
        @current_genre = Array.new()
        remove_current_review()
        write_review()
        @current_genre = Array.new()
        @current_genre = Array.new()
        @albums_location = 'txt/genre_showed.txt'
    end

    def reset()
        wfile = File.new('txt/genre_showed.txt','w')
        wfile.puts 0
        wfile.close
    end

    def save_current_review(albums)
        list = @current_genre
        ############
        rfile = File.new(@albums_location,'r')
        size = rfile.gets.to_i
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets.to_i
            track_name = rfile.gets
            track_location = rfile.gets
            if genre == @option
                list.push title
                list.push artist
                list.push cover
                list.push genre
                list.push track_name
                list.push track_location
            end
        end
        rfile.close
    end

    def reverse_write()
        wfile = File.new(@albums_location,'w')
        wfile.puts @current_genre.size/6
        @current_genre.each do |element| 
            wfile.puts element
        end
        wfile.close()
    end

    def reverse_gerne_music_file_arr()
        list = @current_genre
        rfile = File.new('txt/genre_showed.txt','r')
        size = rfile.gets.to_i
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets.to_i
            track_name = rfile.gets
            track_location = rfile.gets
            #if genre == @option
                list.push title
                list.push artist
                list.push cover
                list.push genre
                list.push track_name
                list.push track_location
            #end
        end
        rfile.close
    end

    def current_albums_genre()
        list = @current_genre
        case @page_call
        when :review
            @albums_location = 'txt/music_file.txt'
        when :approved
            @albums_location = 'txt/approved.txt'
        when :denied
            @albums_location = 'txt/denied.txt'
        end
        rfile = File.new(@albums_location,'r')
        size = rfile.gets.to_i
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets.to_i
            track_name = rfile.gets
            track_location = rfile.gets
            list.push title
            list.push artist
            list.push cover
            list.push genre
            list.push track_name
            list.push track_location
        end
        rfile.close
    end

    def remove_current_review()
        list = @current_genre
        #@albums_location = 'txt/music_file.txt'
        case @page_call
        when :review
            @albums_location = 'txt/music_file.txt'
        when :approved
            @albums_location = 'txt/approved.txt'
        when :denied
            @albums_location = 'txt/denied.txt'
        end
        rfile = File.new(@albums_location,'r')
        size = rfile.gets.to_i
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets.to_i
            track_name = rfile.gets
            track_location = rfile.gets
            if @option != genre
                list.push title
                list.push artist
                list.push cover
                list.push genre
                list.push track_name
                list.push track_location
            end
        end
        rfile.close
    end

    def write_review()
        wfile = File.new(@albums_location,'w')
        wfile.puts @current_genre.size/6
        @current_genre.each do |element| 
            wfile.puts element
        end
        wfile.close()
    end

    def write_to_sort_genre()
        wfile = File.new('txt/genre_showed.txt','w')
        wfile.puts @current_genre.size/6
        @current_genre.each do |element| 
            wfile.puts element
        end
        wfile.close()
    end

    def area_clicked(mouse_x, mouse_y)
        case @user
        when :pick
            if ((mouse_x > 635 && mouse_x < 705) && (mouse_y > 365 && mouse_y < 380))
                @user = :admin
                @text = " "
            elsif ((mouse_x > 618 && mouse_x < 722) && (mouse_y > 386 && mouse_y < 400))
                @user = :curator
                @page_call = :review
                #master(albums)
            end
        when :admin
            case @login_admin
            when :login
                #LOGOUT
                if ((mouse_x > 30 && mouse_x < 124) && (mouse_y > 700 && mouse_y < 720))
                    log_out()
                end
                #SUBMIT
                if ((mouse_x > 754 && mouse_x < 784) && (mouse_y > 553 && mouse_y < 565))
                    @genre_submit = '1'
                end
                if ((mouse_x > 812 && mouse_x < 866) && (mouse_y > 553 && mouse_y < 565))
                    @genre_submit = '2'
                end
                if ((mouse_x > 895 && mouse_x < 930) && (mouse_y > 553 && mouse_y < 565))
                    @genre_submit = '3'
                end
                if ((mouse_x > 953 && mouse_x < 992) && (mouse_y > 553 && mouse_y < 565))
                    @genre_submit = '4'
                end
                if ((mouse_x > 650 && mouse_x < 735) && (mouse_y > 600 && mouse_y < 620))
                    #SUBMIT AREA
                    @albums_location = 'txt/music_file.txt'
                    submit_push()
                    ########
                    submit_gets()
                    ########
                    submit_write()
                    ########
                    @current_albums_reivew = Array.new()
                    @text_fields = Array.new(5) {|index| TextField.new(self, 700, 300 + index * 50)}
                end
            when :logout
                #BACK
                if ((mouse_x > 722 && mouse_x < 768) && (mouse_y > 354 && mouse_y < 365))
                    @user = :pick
                end
                #Login
                if ((mouse_x > 652 && mouse_x < 705) && (mouse_y > 354 && mouse_y < 365))
                    pwd_push()
                    pwd_checking()
                    @admin_account_pwd = Array.new()
                    @login_detail = Array.new(1) {|index| TextField.new(self, 700, 300 + index * 50)}
                end
            end

        when :curator
            albums = load_album()
            i = 0
            t = 0 + @index_album
            x = 190
            y = 60
            #Click review, approved, denied
            if ((mouse_x > 17 && mouse_x < 93) && (mouse_y > 340 && mouse_y < 352))
                pause_changing_pg()
                @option = 5
                master(albums)
                @page_call = :review
                @albums_location = 'txt/music_file.txt'
            end
            if ((mouse_x > 17 && mouse_x < 125) && (mouse_y > 364 && mouse_y < 376))
                pause_changing_pg()
                @page_call = :approved
                @albums_location = 'txt/approved.txt'
            end
            if ((mouse_x > 17 && mouse_x < 90) && (mouse_y > 388 && mouse_y < 400))
                pause_changing_pg()
                @page_call = :denied
                @albums_location = 'txt/denied.txt'
            end
            #LOGOUT
            if ((mouse_x > 30 && mouse_x < 124) && (mouse_y > 700 && mouse_y < 720))
                @option = 5
                master(albums)
                log_out()
            end
            #Click change mode day/night
            if ((mouse_x > 1240 && mouse_x < 1265) && (mouse_y > 670 && mouse_y < 700))
                mode_dn()
            end

            #SHOW BY GENRE
            if ((mouse_x > 46 && mouse_x < 141) && (mouse_y > 524 && mouse_y < 536))
                @option = 1
                master(albums)
            end
            if ((mouse_x > 46 && mouse_x < 141) && (mouse_y > 544 && mouse_y < 556))
                @option = 2
                master(albums)
            end
            if ((mouse_x > 46 && mouse_x < 141) && (mouse_y > 564 && mouse_y < 576))
                @option = 3
                master(albums)
            end
            if ((mouse_x > 46 && mouse_x < 141) && (mouse_y > 584 && mouse_y < 596))
                @option = 4
                master(albums)
            end

            ####
            #### Making click box for each albums
            case @page_call
            when :review,:approved,:denied
                while i < albums.length && i < (@albums_per_page*(@page+1))
                    if ((mouse_x > x && mouse_x < x+20) && (mouse_y > y && mouse_y < y+20))
                        @album_id = t
                        play(@album_id)
                    end
                    #Info Button
                    if ((mouse_x > 680 && mouse_x < 707) && (mouse_y > y && mouse_y < y+20))
                        @album_id = t
                        @page_call = :info
                    end 
                    ###### 
                    if ((mouse_x > x && mouse_x < x+20) && (mouse_y > y*(i+1) && mouse_y < y*(i+1)+20))
                        @album_id = @index_album+ i 
                        
                        play(@album_id)
                    end
                    if ((mouse_x > 680 && mouse_x < 707) && (mouse_y > y*(i+1) && mouse_y < (y+5)*(i+1)+20))
                        @album_id = @index_album+ i 
                        @page_call = :info
                    end
                    i+=1
                end
                #### Making click box for play_pause
                if @song
                    if @song.playing?
                        if ((mouse_x > @x_button && mouse_x < @x_button+60) && (mouse_y > 650 && mouse_y < 650+60))
                            @song.pause
                        end
                    end
                end
            when :info
                if ((mouse_x > 450 && mouse_x < 470) && (mouse_y > 450 && mouse_y < 470))
                    @status = 'txt/approved.txt'
                    status_function(albums)           
                elsif ((mouse_x > 485 && mouse_x < 515) && (mouse_y > 450 && mouse_y < 480))
                    @status = 'txt/denied.txt'
                    status_function(albums)  
                end
            end
        end   
    end

    #Function Adding / Remove from main Music File to Approved back and forward

    def status_function(albums)
        list = @approved_albums_array
        if !list.include? "#{albums[@album_id].track.name.chomp.to_s}"
            list.push albums[@album_id].title rescue nil 
            list.push albums[@album_id].artist rescue nil 
            list.push albums[@album_id].artwork rescue nil 
            list.push albums[@album_id].genre rescue nil 
            list.push albums[@album_id].track.name rescue nil 
            list.push albums[@album_id].track.location rescue nil
            saved_approved_albums(albums)
            approved_function(albums)
            #saved_albums(albums)
            saved_albums_from_review(albums)
            remove_approved_from_review_func(albums)
            @approved_albums_array = Array.new()
            @current_albums_reivew = Array.new()
            @page_call = :review
        else
            list.delete albums[@album_id].title rescue nil 
            list.delete albums[@album_id].artist rescue nil 
            list.delete albums[@album_id].artwork rescue nil 
            list.delete albums[@album_id].genre rescue nil 
            list.delete albums[@album_id].track.name rescue nil 
            list.delete albums[@album_id].track.location rescue nil 
            @page_call = :review
        end
    end

    def saved_approved_albums(albums) #Main
        rfile = File.new(@status,'r')
        size = rfile.gets.to_i
        list = @approved_albums_array
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets
            track_name = rfile.gets
            track_location = rfile.gets
            if track_name != albums[@album_id].track.name #checking whether if the track is already added
                list.push title
                list.push artist
                list.push cover
                list.push genre
                list.push track_name
                list.push track_location
            end
        end
        rfile.close
    end


    def approved_function(albums) #Main
        wfile = File.new(@status,'w')
        wfile.puts @approved_albums_array.size/6
        @approved_albums_array.each do |element| 
            wfile.puts element
        end
        wfile.close()
    end

    def remove_approved_from_review_func(albums) #Main
        wfile = File.new(@albums_location,'w')
        wfile.puts @current_albums_reivew.size/6
        @current_albums_reivew.each do |element|
            wfile.puts element
        end
        wfile.close

    end

    def saved_albums_from_review(albums) #Main
        rfile = File.new(@albums_location,'r')
        size = rfile.gets.to_i
        list = @current_albums_reivew
        for i in 0..(size-1)
            title = rfile.gets
            artist = rfile.gets
            cover = rfile.gets
            genre = rfile.gets
            track_name = rfile.gets
            track_location = rfile.gets
            if track_name != albums[@album_id].track.name #checking whether if the track is already added
                list.push title
                list.push artist
                list.push cover
                list.push genre
                list.push track_name
                list.push track_location
            end
        end
        rfile.close
    end

    ############################

    def draw_info(albums)
        @bmp = Gosu::Image.new(albums[@album_id].artwork)
        @bmp.draw(162, 270, z = ZOrder::PLAYER, 0.5, 0.5)
        head = @font.draw("#{albums[@album_id].artist.chomp} - #{albums[@album_id].track.name}", 450, 330, ZOrder::UI, 1, 1, @font_color)
        @font.draw("Submission Infomation", 450, 350, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Artist: #{albums[@album_id].artist}", 450, 370, ZOrder::UI, 0.7, 0.7, @font_color)
        @font.draw("Title: #{albums[@album_id].track.name} ", 450, 390, ZOrder::UI, 0.7, 0.7, @font_color)
        @font.draw("Genre: " + $genre_names[albums[@album_id].genre.to_i], 450, 410, ZOrder::UI, 0.7, 0.7, @font_color)    
        draw_button_info()
    end

    def draw_button_info()
        @approved_button.draw(450,450,ZOrder::PLAYER,0.03,0.03) #tick
        @denied_button.draw(480,445,ZOrder::PLAYER,0.01,0.01) #denied
    end
    

    def draw_button()
        @x_button = 180
        @y_button = 50
        albums = load_album()
        i = @index_album
        
        while i < albums.length && i < (@albums_per_page*(@page+1)) 
            @play_button.draw(@x_button,@y_button,ZOrder::PLAYER,0.09,0.09)
            @info_button.draw(@x_button+500,@y_button+10,ZOrder::PLAYER,0.03,0.03) #info
            i+=1
            @y_button += 60
            if @song
                if @song.playing?
                    @font.draw("#{albums[@album_id].track.name}", @x_button+ 40, 665, ZOrder::UI, 0.7, 0.7, @font_color)
                    @pause_button.draw(@x_button,650,ZOrder::PLAYER,0.09,0.09)
                else
                    @play_button.draw(@x_button,650,ZOrder::PLAYER,0.09,0.09)
                end
            else
                @play_button.draw(@x_button,650,ZOrder::PLAYER,0.09,0.09)
            end
        end
        
    end
    
    def play(i)
        albums = load_album()
        @song = Gosu::Song.new(albums[i].track.location)
        @song.play(false)
    end

    def update
        albums = load_album()
        #case @option
        #when 5
        #    master(albums)
        #    case @page_call
        #    when :review
        #        @albums_location = 'txt/music_file.txt'
        #    when :approved
        #        @albums_location = 'txt/approved.txt'
        #    when :denied
        #        @albums_location = 'txt/denied.txt'
        #    end  
        #end
        if @song
            if @song.playing?
                if button_down?(Gosu::KbSpace)
                    button_function("space")
                end
            end
        end
    end

    def draw()
        @font.draw("mouse_x: #{mouse_x}", 1000, 0, ZOrder::UI, 0.5, 0.5, @font_color)
        @font.draw("mouse_y: #{mouse_y}", 1000, 20, ZOrder::UI, 0.5, 0.5, Gosu::Color::BLUE)
        draw_background()
        case @user
        when :pick
            pick_draw()
        when :admin
            case @login_admin
            when :login
                @font.draw("LOGOUT", 30, 695, ZOrder::UI, 1, 1, @font_color)
                admin_draw()
            when :logout
                admin_login()
            end
        when :curator
            curator_draw()
            
            @font.draw("LOGOUT", 30, 695, ZOrder::UI, 1, 1, @font_color)
        end
    end

    def admin_login()
        @font.draw("Password:", 500, 300, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("LOGIN", 650, 350, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("BACK", 720, 350, ZOrder::UI, 0.8, 0.8, @font_color)
        @login_detail.each { |tf| tf.draw(0)}
    end

    def admin_draw()
        @font.draw("Album Title:", 500, 300, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Album Artist:", 500, 350, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Artwork Path:", 500, 400, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Track Name:", 500, 450, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Track Path:", 500, 500, ZOrder::UI, 0.8, 0.8, @font_color)
        @font.draw("Genre:                                      Pop     Classic     Jazz    Rock", 500, 550, ZOrder::UI, 0.8, 0.8, @font_color)
        @text_fields.each { |tf| tf.draw(0)}
        @font.draw("SUBMIT", 650, 600, ZOrder::UI, 1, 1, @font_color)
    end

    def pick_draw()
        @font.draw("ADMIN", 635, 360, ZOrder::UI, 1.0, 1.0, @font_color)
        @font.draw("CURATOR", 615, 380, ZOrder::UI, 1.0, 1.0, @font_color)
        @user_ico.draw(660,330,ZOrder::PLAYER,0.05,0.05)
    end

    def curator_draw()
        @font.draw("mouse_x: #{mouse_x}", 1000, 0, ZOrder::UI, 0.5, 0.5, @font_color)
        @font.draw("mouse_y: #{mouse_y}", 1000, 20, ZOrder::UI, 0.5, 0.5, Gosu::Color::BLUE)
        @font.draw("REVIEW", 15, 335, ZOrder::UI, 0.9, 0.9, @font_color)
        @font.draw("APPROVED", 15, 360, ZOrder::UI, 0.9, 0.9, @font_color)
        @font.draw("DENIED", 15, 385, ZOrder::UI, 0.9, 0.9, @font_color)
        @font.draw("    SHOW BY GENRE
            1. POP
            2. CLASSIC
            3. JAZZ
            4. ROCK", -18, 500, ZOrder::UI, 0.8, 0.8, @font_color)
        @darkmode_ico.draw(1240,670,ZOrder::PLAYER,0.05,0.05)
        albums = load_album()
        case @page_call
        when :review
            #draw_tracks_by_genre(albums,option)
            draw_tracks(albums)
            #@albums_location = 'txt/music_file.txt'
            if albums.size > 0
                @font.draw("Review: #{albums.size} track", 1100, 675, ZOrder::UI, 0.5, 0.5, @font_color) rescue nil
            end
        when :info
            draw_info(albums)
        when :approved
            #draw_tracks_by_genre(albums,option)
            draw_tracks(albums)
            #@albums_location = 'txt/approved.txt'
            if albums.size > 0
                @font.draw("Approved: #{albums.size} track", 961, 60, ZOrder::UI, 0.9, 0.9, @font_color) rescue nil
            end
        when :denied
            #draw_tracks_by_genre(albums,option)
            draw_tracks(albums)
            #@albums_location = 'txt/denied.txt'
            if albums.size > 0
                @font.draw("Denied: #{albums.size} track", 961, 60, ZOrder::UI, 0.9, 0.9, @font_color) rescue nil
            end
        end
    end

    def button_down(id)
        albums = load_album()
        case id
        when Gosu::KB_TAB
            case @user
            when :admin
                # Tab key will not be 'eaten' by text fields; use for switching through
                # text fields.
                case @login_admin
                when :login
                    index = @text_fields.index(self.text_input) || -1
                    self.text_input = @text_fields[(index + 1) % @text_fields.size]
                when :logout
                    index = @login_detail.index(self.text_input) || -1
                    self.text_input = @login_detail[(index + 1) % @login_detail.size]
                end
            when Gosu::KB_ESCAPE
                # Escape key will not be 'eaten' by text fields; use for deselecting.
                if self.text_input
                    self.text_input = nil
                end
            end
        when Gosu::MsLeft
            @locs = [mouse_x, mouse_y]
            area_clicked(mouse_x,mouse_y)
            case @user
            when :admin
                case @login_admin
                when :login
                    # Mouse click: Select text field based on mouse position.
                    self.text_input = @text_fields.find { |tf| tf.under_mouse?}
                when :logout
                    # Mouse click: Select text field based on mouse position.
                    self.text_input = @login_detail.find { |tf| tf.under_mouse?}
                end
                # Also move caret to clicked position
                self.text_input.move_caret_to_mouse unless self.text_input.nil?
                super
            end
        when 260 #Scroll Down
            if @page >= 0 && @page < (albums.size)/10 - (1-albums.size%2)
                @page +=1
                @index_album+=10
            end
        when 259 #Scroll Up 
            if @page > 0
                @page -= 1
                @index_album-=10
            end
        end
    end
end
Application.new.show