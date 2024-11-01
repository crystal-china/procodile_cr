module Procodile
  class CLI
    module RestartCommand
      macro included
        options :restart do |opts, cli|
          opts.on("-p", "--processes a,b,c", "Only restart the listed processes or process types") do |processes|
            cli.options.processes = processes
          end

          opts.on("-t", "--tag TAGNAME", "Tag all started processes with the given tag") do |tag|
            cli.options.tag = tag
          end
        end
      end

      def restart
        if supervisor_running?
          instances = ControlClient.run(
            @config.sock_path,
            "restart",
            processes: process_names_from_cli_option,
            tag: @options.tag,
          ).as Array(Tuple(InstanceConfig?, InstanceConfig?))

          if instances.empty?
            puts "There are no processes to restart."
          else
            instances.each do |old_instance, new_instance|
              if old_instance && new_instance
                if old_instance.description == new_instance.description
                  puts "Restarted".color(35) + " #{old_instance.description}"
                else
                  puts "Restarted".color(35) + " #{old_instance.description} -> #{new_instance.description}"
                end
              elsif old_instance
                puts "Stopped".color(31) + " #{old_instance.description}"
              elsif new_instance
                puts "Started".color(32) + " #{new_instance.description}"
              end
              STDOUT.flush
            end
          end
        else
          raise Error.new "Procodile supervisor isn't running"
        end
      end
    end
  end
end
