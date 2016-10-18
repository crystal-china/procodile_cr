require 'procodile/instance'

module Procodile
  class Process

    MUTEX = Mutex.new

    attr_reader :config
    attr_reader :name
    attr_accessor :command
    attr_accessor :options
    attr_accessor :log_color
    attr_accessor :removed

    def initialize(config, name, command, options = {})
      @config = config
      @name = name
      @command = command
      @options = options
      @log_color = 0
      @instance_index = 0
    end

    #
    # Increase the instance index and return
    #
    def get_instance_id
      MUTEX.synchronize do
        @instance_index = 0 if @instance_index == 10000
        @instance_index += 1
      end
    end

    #
    # How many instances of this process should be started
    #
    def quantity
      @options['quantity'] || 1
    end

    #
    # The maximum number of times this process can be respawned in the given period
    #
    def max_respawns
      @options['max_respawns'] ? @options['max_respawns'].to_i : 5
    end

    #
    # The respawn window. One hour by default.
    #
    def respawn_window
      @options['respawn_window'] ? @options['respawn_window'].to_i : 3600
    end

    #
    # Return the path where log output for this process should be written to. If
    # none, output will be written to the supervisor log.
    #
    def log_path
      @options['log_path'] ? File.expand_path(@options['log_path'], @config.root) : nil
    end

    #
    # Return the signal to send to terminate the process
    #
    def term_signal
      @options['term_signal'] || 'TERM'
    end

    #
    # Defines how this process should be restarted
    #
    # start-term = start new instances and send term to children
    # usr1 = just send a usr1 signal to the current instance
    # usr2 = just send a usr2 signal to the current instance
    # term-start = stop the old instances, when no longer running, start a new one
    #
    def restart_mode
      @options['restart_mode'] || 'term-start'
    end

    #
    # Generate an array of new instances for this process (based on its quantity)
    #
    def generate_instances(supervisor, quantity = self.quantity)
      quantity.times.map { |i| create_instance(supervisor) }
    end

    #
    # Create a new instance
    #
    def create_instance(supervisor)
      Instance.new(supervisor, self, get_instance_id)
    end

    #
    # Return a hash
    #
    def to_hash
      {
        :name => self.name,
        :log_color => self.log_color,
        :quantity => self.quantity,
        :max_respawns => self.max_respawns,
        :respawn_window => self.respawn_window,
        :command => self.command,
        :restart_mode => self.restart_mode,
        :log_path => self.log_path,
        :removed => self.removed ? true : false
      }
    end

  end
end
