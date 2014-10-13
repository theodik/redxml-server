require 'nokogiri'
require 'redxml/server/version'
require 'redxml/server/logging'
require 'redxml/server/driver/base'
require 'redxml/server/driver/redis'
require 'redxml/server/launcher'
require 'redxml/server/transformer'
require 'redxml/server/xquery'

module RedXML
  module Server
    DEFAULTS = {
    }.freeze

    def self.options
      @options ||= DEFAULTS.dup
    end

    def self.options=(opts)
      @options = opts
    end

    def self.logger
      RedXML::Server::Logging.logger
    end

    def self.logger=(log)
      RedXML::Server::Logging.logger = log
    end

    def self.configure
      yield self
    end
  end
end
