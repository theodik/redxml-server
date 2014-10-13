require 'singleton'
require 'optparse'

require 'redxml/server'

module RedXML
  module Server
    class CLI
      include Singleton unless $TESTING

      def parse(args = ARGV)
        setup_options(args)
        initialize_logger
        validate!
        daemonize
        write_pid
      end

      def run
        logger.info 'RedXML'
        logger.info "Running in #{RUBY_DESCRIPTION}"

        require 'redxml/server/launcher'
        launcher = RedXML::Server::Launcher.new(options)
        begin
          launcher.run
        rescue Interrupt
          logger.info 'Shutting down'
          launcher.stop
          exit(0)
        end
      end

      private

      def options
        RedXML::Server.options
      end

      def setup_options(args)
        opts = parse_options(args)

        cfile = opts[:config_file]
        opts.merge! parse_config(cfile) if cfile

        options.merge!(opts)
      end

      def parse_options(argv)
        opts = {}

        parser = OptionParser.new do |o|
          o.banner = 'redxml-server [options]'

          o.on '-v', '--verbose', 'Print more verbose output' do |arg|
            opts[:verbose] = arg
          end

          o.on '-L', '--logfile PATH', 'Path to logfile' do |arg|
            opts[:logfile] = arg
          end

          o.on '-P', '--pidfile PATH', 'Path to pidfile' do |arg|
            opts[:pidfile] = arg
          end

          o.on '-c', '--config PATH', 'path to YAML config file' do |arg|
            opts[:config_file] = arg
          end

          o.on '-C', '--concurency INT', 'processor threads to use' do |arg|
            opts[:concurency] = arg.to_i
          end

          o.on_tail '-h', '--help', 'Show help' do
            logger.info parser
            die 1
          end
        end
        parser.parse!(argv)

        if File.exist?('config/redxml-server.yml')
          opts[:config_file] = 'config/redxml-server.yml'
        end
        opts
      end

      def parse_config(config_file)
      end

      def initialize_logger
        RedXML::Server::Logging.initialize_logger(options[:logfile]) if options[:logfile]

        RedXML::Server::Logging.logger.level = ::Logger::DEBUG if options[:verbose]
      end

      def validate!
      end

      def daemonize
        return unless options[:daemon]
        fail NotImplementedError, 'Daemonizing is not implemented yet.'
      end

      def write_pid
        return unless options[:pidfile]

        pidfile = File.expand_path(options[:pidfile])
        File.open(pidfile, 'w') do |f|
          f.puts ::Process.pid
        end
      end
    end
  end
end
