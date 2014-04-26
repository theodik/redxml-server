module RedXML
  module Server
    module XQuery
      module Solvers
        class Function
          def initialize(environment, collection)
            @environment = environment
            @collection = collection
          end

          def doc(file_name) # returns KeyBuilder
            env_id = Transformer::MappingService.map_env(@environment)
            coll_id = Transformer::MappingService.map_coll(env_id, @collection)
            document_service = Transformer::DocumentService.new(env_id, coll_id)
            file_id = document_service.get_document_id(file_name)
            if file_id.nil?
              fail QueryStringError, "file #{file_name} not found in database"
            end
            Transformer::KeyBuilder.new(env_id, coll_id, file_id)
          end
        end
      end
    end
  end
end
