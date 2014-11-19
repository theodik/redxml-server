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
          prepare_result @xquery.execute @query
        end

        private

        def prepare_result(xml)
          if xml.is_a? Array
            xml.map{|i| i.respond_to?(:to_html) ? i.to_html : i }.join(',')
          else
            xml.to_html
          end
        end
      end

      class SaveDocument
        def initialize(db_interface, param)
          @db_interface = db_interface
          @env, @col, @document_name, @document = param.split("\1", 4)
        end

        def execute
          env_id = get_env(@env) || create_env(@env)
          col_id = get_col(col_id, @col) || create_col(env_id, @col)
          service = RedXML::Server::Transformer::DocumentService.new(@db_interface, env_id, col_id)
          result = service.save_document(@document_name, @document)
          'ok' if result
        end

        private

        def get_env(name)
          RedXML::Server::Transformer::MappingService.map_env(@db_interface, name)
        rescue RedXML::Server::Transformer::MappingException
          nil
        end

        def create_env(name)
          service = RedXML::Server::Transformer::EnvironmentService.new(@db_interface)
          service.create_environment(name)
        end

        def get_col(env_id, name)
          RedXML::Server::Transformer::MappingService.map_coll(@db_interface, env_id, name)
        rescue RedXML::Server::Transformer::MappingException
          nil
        end

        def create_col(env_id, name)
          service = RedXML::Server::Transformer::CollectionService.new(@db_interface, env_id)
          service.create_child_collection(name)
        end
      end

      class LoadDocument
        def initialize(db_interface, param)
          @db_interface = db_interface
          @env, @col, @document_name = param.split("\1", 3)
        end

        def execute
          env_id = RedXML::Server::Transformer::MappingService.map_env(@db_interface, @env)
          col_id = RedXML::Server::Transformer::MappingService.map_coll(@db_interface, env_id, @col)
          service = RedXML::Server::Transformer::DocumentService.new(@db_interface, env_id, col_id)
          document = service.find_document(@document_name)
          document.to_html
        end
      end
    end
  end
end
