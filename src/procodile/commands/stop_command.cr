module Procodile
  class CLI
    module StopCommand
      macro included
        options :stop do |opts, cli|
          opts.on("-p", "--processes a,b,c", "Only stop the listed processes or process types") do |processes|
            cli.options.processes = processes
          end

          opts.on("-s", "--stop-supervisor", "Stop the supervisor process when all processes are stopped") do
            cli.options.stop_supervisor = true
          end

          opts.on("--wait", "Wait until supervisor has stopped before exiting") do
            cli.options.wait_until_supervisor_stopped = true
          end
        end
      end

      def stop
        if supervisor_running?
          instances = ControlClient.run(
            @config.sock_path,
            "stop",
            processes: process_names_from_cli_option,
            stop_supervisor: @options.stop_supervisor,
          ).as(Array(InstanceConfig))

          if instances.empty?
            puts "No processes were stopped."
          else
            instances.each do |instance|
              puts "Stopped".color(31) + " #{instance.description} (PID: #{instance.pid})"
            end
          end

          if @options.stop_supervisor
            puts "Supervisor will be stopped when processes are stopped."
          end

          if @options.wait_until_supervisor_stopped
            puts "Waiting for supervisor to stop..."
            loop do
              sleep 1.second
              if supervisor_running?
                sleep 1.second
              else
                puts "Supervisor has stopped"
                exit 0
              end
            end
          end
        else
          raise Error.new "Procodile supervisor isn't running"
        end
      end
    end
  end
end
