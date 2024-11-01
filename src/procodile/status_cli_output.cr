require "./message"

module Procodile
  class StatusCLIOutput
    def initialize(@status : Procodile::ControlClientReplyForStatusCommand)
    end

    def print_all
      print_header
      print_processes
    end

    def print_header
      puts "Procodile Version   #{@status.version.to_s.color(34)}"
      puts "Application Root    #{(@status.root).to_s.color(34)}"
      puts "Supervisor PID      #{(@status.supervisor["pid"]).to_s.color(34)}"
      if (time = @status.supervisor["started_at"])
        time = Time.unix(time)
        puts "Started             #{time.to_s.color(34)}"
      end
      if !@status.environment_variables.empty?
        @status.environment_variables.each_with_index do |(key, value), index|
          if index == 0
            print "Environment Vars    "
          else
            print "                    "
          end
          print key.color(34)
          puts " #{value}"
        end
      end
      unless @status.messages.empty?
        puts
        @status.messages.each do |message|
          puts "\e[31m * #{Message.parse(message)}\e[0m"
        end
      end
    end

    def print_processes
      puts
      @status.processes.each_with_index do |process, index|
        puts unless index == 0
        puts "|| ".color(process.log_color) + process.name.color(process.log_color)
        puts "#{"||".color(process.log_color)} Quantity            #{process.quantity}"
        puts "#{"||".color(process.log_color)} Command             #{process.command}"
        puts "#{"||".color(process.log_color)} Respawning          #{process.max_respawns} every #{process.respawn_window} seconds"
        puts "#{"||".color(process.log_color)} Restart mode        #{process.restart_mode}"
        puts "#{"||".color(process.log_color)} Log path            #{process.log_path || "none specified"}"
        puts "#{"||".color(process.log_color)} Address/Port        #{process.proxy_port ? "#{process.proxy_address}:#{process.proxy_port}" : "none"}"
        instances = @status.instances[process.name]
        if instances.empty?
          puts "#{"||".color(process.log_color)} No processes running."
        else
          instances.each do |instance|
            print "|| => ".color(process.log_color) + instance.description.to_s.ljust(17, ' ').color(process.log_color)
            print instance.status.ljust(10, ' ')
            print "   #{formatted_timestamp(instance.started_at).ljust(10, ' ')}"
            print "   pid:#{instance.pid.to_s.ljust(6, ' ')}"
            print "   respawns:#{instance.respawns.to_s.ljust(4, ' ')}"
            print "   port:#{(instance.port || '-').to_s.ljust(6, ' ')}"
            print "   tag:#{instance.tag || '-'}"
            puts
          end
        end
      end
    end

    private def formatted_timestamp(timestamp)
      return "" if timestamp.nil?

      timestamp = Time.unix(timestamp)
      if timestamp > (Time.local - (60 * 60 * 24).seconds)
        timestamp.to_s("%H:%M")
      else
        timestamp.to_s("%d/%m/%Y")
      end
    end
  end
end
