module RedXML
  module Server
    module Executors
      class Ping
        def initialize(db_interface, _param)
        end

        def execute
        end
      end

      class Execute
        def initialize(db_interface, param)
          @db_interface = db_interface
          @env, @col, @query = param.split("\1", 3)
          @xquery = RedXML::Server::XQuery::Executor.new(@db_interface, @env, @col)
        end

        def execute
          require 'pry'; binding.pry
          prepare_result @xquery.execute @query
        end

        private

        def prepare_result(xml)
          xml.to_html
        end
      end
    end
  end
end
