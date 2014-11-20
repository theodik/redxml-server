require 'logger'

module RedXML
  module Server
    module Logging
      class Pretty < Logger::Formatter
        # Provide a call() method that returns the formatted message.
        def call(severity, time, program_name, message)
          "#{time.utc.iso8601(3)} #{::Process.pid} TID-#{Thread.current.object_id.to_s(36)} #{severity}: #{message}\n"
        end
      end

      def self.logger
        defined?(@logger) ? @logger : initialize_logger
      end

      def self.logger=(log)
        @logger = (log ? log : Logger.new('/dev/null'))
      end

      def self.initialize_logger(log_target = STDOUT)
        oldlogger = defined?(@logger) ? @logger : nil
        @logger = Logger.new(log_target)
        @logger.level = Logger::INFO
        @logger.formatter = Pretty.new
        oldlogger.close if oldlogger && !$TESTING # don't want to close testing's STDOUT logging
        @logger
      end
    end

    def logger
      RedXML::Server::Logging.logger
    end
  end
end
