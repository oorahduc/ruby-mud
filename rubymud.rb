require 'socket'
require 'thread'

# Threaded mud client with support for aliases via aliases.conf file

class Connection
  def initialize
    @buffersize = 20000
    @hostname = 'realmsofdespair.com'
    @port = 4000
    @aliases = Hash[File.read('aliases.conf').split("\n").map{|i|i.split(':')}]
    @connected = false
    @input = ""
  end

  def connect
    begin
      @s = TCPSocket.open(@hostname, @port)
      puts "Connection established to #{@hostname} on port #{@port}"
      @connected = true
    rescue
      puts "Connection failed."
      @connected = false
    end
    output
  end

  def output
    sleep(0.5)
    while @connected == true
      @response = @s.recvfrom(@buffersize)
      puts @response
      if @input == "quit"
        sleep(1)
        @connected = false
        @s.close
        exit
      end
    end
  end

  def prompt
    loop do
      begin
        @input = gets.chomp
      rescue Interrupt => e
        @connected = false
        puts " - Quitting"
        exit
      rescue StandardError => e
        @connected = false
        raise
      end
      process_input(@input)
    end
  end

  def process_input(i)
    if @aliases.key?(i)
      puts "\r" + ("\e[A\e[K"*3)
      STDOUT.flush
      puts @aliases[i]
      @s.puts(@aliases[i])
    else
      @s.puts(@input)
    end
  end

  def close
    @s.close
  end
end

mud = Connection.new

t1 = Thread.new { mud.connect }
t2 = Thread.new { mud.prompt }

t1.join
t2.join
