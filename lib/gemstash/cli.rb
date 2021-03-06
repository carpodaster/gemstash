require "gemstash"
require "thor"

module Gemstash
  #:nodoc:
  class CLI < Thor
    autoload :Setup, "gemstash/cli/setup"
    autoload :Start, "gemstash/cli/start"
    autoload :Stop,  "gemstash/cli/stop"

    def self.exit_on_failure?
      true
    end

    desc "setup", "Checks for dependencies and does initial setup"
    method_option :redo, :type => :boolean, :default => false, :desc =>
      "Redo configuration"
    method_option :debug, :type => :boolean, :default => false, :desc =>
      "Show detailed errors"
    method_option :config_file, :type => :string, :desc =>
      "Config file to save to"
    def setup
      Gemstash::CLI::Setup.new(self).run
    end

    desc "start", "Starts your gemstash server"
    method_option :daemonize, :type => :boolean, :default => true, :desc =>
      "Daemonize the server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when starting"
    def start
      Gemstash::CLI::Start.new(self).run
    end

    desc "stop", "Stops your gemstash server"
    method_option :config_file, :type => :string, :desc =>
      "Config file to load when stopping"
    def stop
      Gemstash::CLI::Stop.new(self).run
    end
  end
end
