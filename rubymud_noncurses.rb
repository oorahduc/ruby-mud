require 'socket'
require 'thread'
require 'curses'
require './util.rb'

# Threaded mud client with support for aliases via aliases.conf file

#Curses.init_screen()

class Connection
  def initialize
    # Server parameters
    @hostname = 'realmsofdespair.com'
    @port = 4000
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
      @response = @s.recvfrom(@buffersize)
      puts @response
      promptbar
      if @input == "quit"
        sleep(1)
        @connected = false
        @s.close
        exit
      end
    end
  end

  def promptbar
    @rows, @cols = winsize
    @bar = "#" * @cols.to_i
    puts @bar.bg_blue.blue
  end

  def prompt
    # User input
    loop do
      begin
        @input = gets.chomp
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
    end
  end

  # Deprecated - Unused. Holding onto the old code for now.
  def deprecated_process_input(i)
    # Filter user input for aliases
    if @aliases.key?(i)
      puts "\r" + ("\e[A\e[K"*3)
      STDOUT.flush
      puts @aliases[i]
      @s.puts(@aliases[i])
    else
      @s.puts(@input)
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
      puts "\r" + ("\e[A\e[K"*3)
      # $STDOUT.flush
      puts @input
      @s.puts(@input)
    end
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
