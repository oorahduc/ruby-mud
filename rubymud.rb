require 'socket'
require 'thread'
require 'curses'
require 'readline'
require './util.rb'

# Threaded mud client with support for aliases via aliases.conf file

Curses.init_screen
Curses.curs_set(1)

class Connection
  def initialize
    # @win1 = Curses::Window.new(Curses.lines / 1 - 2, Curses.cols / 1 - 1, 0, 0)
    # @win1.setpos(1, 2)
    # @win1.refresh
    @input_panel = Curses::Window.new(2, Curses.cols, Curses.lines - 2, 1)
    # @input_panel.box("|", "-")
    @input_panel.refresh
    @input_panel.setpos(1, 1)

    # Server parameters
    @hostname, @port = ARGV
    # @hostname = 'realmsofdespair.com'
    # @port = 4000
    # Setup aliases
    @aliases = Hash[File.read('aliases.conf').split("\n").map{|i|i.split(':')}]
    # Initialize basic params
    @buffersize = 20000
    @connected = false
    @input = ""
  end

  def connect
    # Initialize connection
    begin
      @s = TCPSocket.open(@hostname, @port)
      puts "Connection established to #{@hostname}:#{@port}"
      @connected = true
    rescue
      puts "Connection failed."
      @connected = false
    end
    output
  end

  def output
    # Output stream from the server
    sleep(0.5)
    while @connected == true
      # print "\n"
      @response = @s.recvfrom(@buffersize)
      puts @response
      # promptbar
      if @input == "quit"
        sleep(1)
        @connected = false
        @s.close
        exit
      end
      @input_panel.setpos(1, 1)
      @input_panel.refresh
      @input_panel << @input
    end
  end

  def promptbar
    @rows, @cols = winsize
    @bar = "#" * @input_panel.maxx
    @input_panel << @bar.bg_blue.blue
  end

  def prompt
    # User input
    loop do
      # puts @input_panel
      begin
        @input_panel << @input = Readline.readline("> ", true)
        if @input == "quit"
          exit
        else
          @input_panel.refresh
          # p Readline::HISTORY.to_a
          # print("-> ", buf, "\n")
        end
      rescue Interrupt => e
        @connected = false
        puts " - Quitting"
        puts "\r" + ("\e[A\e[K"*3)
        $STDOUT.flush
        exit
      rescue StandardError => e
        @connected = false
        raise
      end
      process_input(@input)
      # @input_panel.setpos(1, 1)
    end
  end

  def process_input(i)
    # Now splits aliases with multiple commands delimited by ;
    if @aliases.key?(i)
      if @aliases[i].include? ";"
        @aliases[i].split(";").each do |a|
          puts a
          sleep(0.5)
          @s.puts(a)
        end
      else
        puts "\r" + ("\e[A\e[K"*3)
        # STDOUT.flush
        puts @aliases[i]
        @s.puts(@aliases[i])
      end
    else
      # puts "\r" + ("\e[A\e[K"*3)
      # $STDOUT.flush
      @s.puts(@input)
    end
    @input_panel.setpos(1, 1)
  end

  def close
    # Close connection
    @s.close
  end
end

mud = Connection.new

t1 = Thread.new { mud.connect }
t2 = Thread.new { mud.prompt }

t1.join
t2.join
