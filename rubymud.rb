require 'socket'

class Connection
  def initialize
    @buffersize = 20000
    @hostname = 'realmsofdespair.com'
    @port = 4000
    @aliases = Hash[File.read('aliases.conf').split("\n").map{|i|i.split(':')}]
  end

  def connect
    begin
      @s = TCPSocket.open(@hostname, @port)
      puts "Connection established to #{@hostname} on port #{@port}"
    rescue
      puts "Connection failed."
    end
    output
  end

  def output
    sleep(0.5)
    @response = @s.recvfrom(@buffersize)
    puts @response
    if @input == "quit"
      @s.close
    else
      prompt
    end
  end

  def prompt
    begin
      print "> "
      @input = gets.chomp
    rescue Interrupt => e
      puts " - Quitting"
      exit
    rescue StandardError => e
      raise
    end
    process_input(@input)
    output
  end

  def process_input(i)
    if @aliases.key?(i)
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
mud.connect

