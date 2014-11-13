require 'nokogiri'
require 'redxml/server/version'
require 'redxml/server/logging'
require 'redxml/server/database'
require 'redxml/server/server_worker'
require 'redxml/server/launcher'
require 'redxml/server/xml'
require 'redxml/server/transformer'
require 'redxml/server/xquery'

module RedXML
  module Server
    DEFAULTS = {
      db: {
        driver: :redis
      },
      concurency: 25,
      bind: nil,
      port: 33965
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
