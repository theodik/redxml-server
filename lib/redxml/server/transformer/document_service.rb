require "nokogiri"
require "observer"

module RedXML
  module Server
    module Transformer
      class Notifier
      end

      # Class represents a service used to work with whole XML files. It can saves them to the database, verify
      # their existence in a database and also retrives them.
      # This class is part of Observer pattern as observer, it get's notified by XML::SaxDocument class.
      class DocumentService < Notifier
        # Creates new instance of DocumentService
        # ==== Parameters
        # * +env_id+ - Id of the environment
        # * +coll_id+ - Id of the collection
        def initialize(db_interface, env_id, coll_id)
          @xml_transformer = nil
          @db_interface    = db_interface
          @doc_key         = Transformer::KeyBuilder.documents_key(env_id, coll_id)
          @env_info        = Transformer::KeyBuilder.environment_info(env_id)
          @env_id          = env_id
          @coll_id         = coll_id
          @builder         = nil
        end

        # Used to handle events in the terms of Observer pattern. During parsing of XML document
        # parts of it are collected and sent here to be saved into database using XML::Transformer
        # ==== Parameters
        # * +value+ - Part of parsed XML document to be saved into database
        def update(value)
          if value.instance_of? Array
            #Document information are here, [version, encoding, standalone]
            if value[0] == "namespaces"
              value.shift # Delete first member "namespaces"
              key = @builder.namespace_key
              @db_interface.add_to_hash(key, value, true)
            else
              key = @builder.info
              field_values = []
              field_values << "name" << @doc_name
              field_values << "version" << value[0] if value[0] != nil
              field_values << "encoding" << value[1] if value[1] != nil
              field_values << "standalone" << value[2] if value[2] != nil
              @db_interface.add_to_hash(key, field_values, true)
            end
          elsif value.instance_of? String
            #Root element name
            key = @builder.info
            info = ["root", "#{value}"]
            @db_interface.add_to_hash(key, info, true)
          elsif value.instance_of? Hash
            #Element mapping is passed here
            key = @builder.elem_mapping_key()
            #We have to remap our hash to array
            field_values = []
            value.each do |key, value|
              field_values << key << value
            end
            @db_interface.add_to_hash(key, field_values, true)
          else
            #Element here
            @xml_transformer.save_node(value)
          end
        end

        # Creates new unique ID to be used for the creation of new Resources.
        # ==== Return value
        # String with the ID
        def get_possible_id
          @result = @db_interface.increment_hash(@env_info, Transformer::KeyElementBuilder::ITERATOR_KEY, 1)

          #TODO This is needed in some very rare scenarios, i dont' know how it is possible that
          #if we increment the same key twice, we still have the same value, maybe some Redis bug.
          # Currently occurs ONLY when all tests are run, if you run test alone, it works
          if @result == @last_result
            @result = @db_interface.increment_hash(@env_info, Transformer::KeyElementBuilder::ITERATOR_KEY, 1)
          end
          @last_result = @result
          @result
        end

        # Method will save a certain file to the database under the certain collection and environment if
        # it doesn't already exist. SAX parser is used to parse an XML file.
        # ==== Parameters
        # * +file+     - String with path to XML file or document name
        # * +document+ - String with xml document
        # ==== Raises
        # Transformer::MappingException - If document with such a name already exist
        # ==== Return value
        # True if document was saved, false otherwise
        def save_document(file, document = nil)
          if document.nil?
            if !File.file?(file)
              logger.warn "Failed saving document: `#{file}' is not a file."
              return false
            end
            document = File.open(File.absolute_path(file)).read
          end
          file_name = File.basename(file)
          doc_id = get_possible_id
          result = @db_interface.add_to_hash_ne(@doc_key, file_name, doc_id)
          fail Transformer::MappingException, "Document with such a name already exist." unless result

          @builder = Transformer::KeyBuilder.new(@env_id, @coll_id, doc_id)
          @xml_transformer = Transformer::XMLTransformer.new(@db_interface, @builder)

          #Now file is saved, we have it's id and we can know proceed to parsing
          mapping = Transformer::MappingService.new(@db_interface, @builder)
          parser = Nokogiri::XML::SAX::Parser.new(XML::SaxDbWriter.new(self, mapping))
          @doc_name = file_name

          #Main idea here is to use SAX parser, events should be handled by SaxDocument, which
          #will prepare whole nodes and when the node ends, it will send event here (update method) so we
          #can use XmlTranformer to save it.
          parser.parse(document)
          true
        end

        # Finds a document under the certain database and collection.
        # ==== Parameters
        # * +file_name+ - Name of the file to be retrieved
        # ==== Return value
        # Returns instance of Nokogiri::XML::Document
        def find_document(file_name)#:XML::Document
          file_id = get_document_id(file_name)

          if file_id == nil
            fail Transformer::MappingException, "Document with name #{file_name} not found."
            return nil
          end
          @builder = Transformer::KeyBuilder.new(@env_id, @coll_id, file_id)
          @xml_transformer = Transformer::XMLTransformer.new(@db_interface, @builder)
          @xml_transformer.get_document(@builder)
        end

        # Method will save a certain file to the database under the certain collection and environment if
        # it doesn't already exist. SAX parser is used to parse an XML file.
        # ==== Parameters
        # * +resource+ - XMLResource instance to be saved in database
        # ==== Raises
        # Transformer::MappingException - If document with such a name already exist
        # ==== Return value
        # True if resource was saved, false otherwise
        def save_resource(resource)
          if !resource.respond_to?(:get_content_as_sax)
            logger.warn "Saving resource failed: Parameter is not a valid resource"
            return false
          end

          name = resource.get_document_id
          doc_id = resource.doc_id
          result = @db_interface.add_to_hash_ne(@doc_key, name, doc_id)
          fail Transformer::MappingException, "Document with such a name already exist." unless result

          @builder = Transformer::KeyBuilder.new(@env_id, @coll_id, doc_id)
          @xml_transformer = Transformer::XMLTransformer.new(@db_interface, @builder)
          info = [name, doc_id]
          #Now file is saved, we have it's id and we can now proceed to parsing
          mapping = Transformer::MappingService.new(@db_interface, @builder)
          handler = RedXML::Server::XML::SaxDbWriter.new(self, mapping)
          @doc_name = name
          dc = resource.get_content_as_dom
          resource.get_content_as_sax(handler)
          true
        end

        # # Finds a resource under the certain database and collection.
        # # ==== Parameters
        # # * +name+ - Name of the resource to be retrieved
        # # ==== Raises
        # # Transformer::MappingException - If resource with such a name does not exist
        # # ==== Return value
        # # Returns instance of XMLDBApi::RedXMLResource
        # def get_resource(name)#:XML::Document
        #   file_id = get_document_id(name)
        #   if file_id == nil
        #     fail Transformer::MappingException, "Document with name #{name} not found."
        #   end
        #   XMLDBApi::RedXmlResource.new(@env_id, @coll_id, name, file_id, nil, XMLDBApi::RedXmlResource::STATE_LAZY)
        # end

        # Moves one resource from it's current collection into another one in constant time.
        # Note: Only persisted resources should be moved this way, because only content in database
        # is moved, not the content of resource instance itself. Any
        # ==== Parameters
        # * +res+ - RedXMLResource instance which should be moved
        # * +target_coll_id+ - Id of the collection in which the given resource should be moved into
        # ==== Raises
        # Transformer::MappingException - If the target collection already contains resource with
        # the same name
        def move_resource(res, target_coll_id)
          target_service = self.class.new(@env_id, target_coll_id)
          existence = target_service.document_exist?(res.get_document_id)
          fail Transformer::MappingException, "Cannot move resource, target collection does contain document with the same name, name=#{res.get_document_id}" if existence

          result = @db_interface.pipelined do
            # Create mapping in the new collection
            key = Transformer::KeyBuilder.documents_key(res.db_id, target_coll_id)
            @db_interface.add_to_hash key, [res.doc_name, res.doc_id]
            # Delete mapping in the old collection
            key_builder = Transformer::KeyBuilder.new(res.db_id, res.coll_id, res.doc_id)
            key_builder_new = Transformer::KeyBuilder.new(res.db_id, target_coll_id, res.doc_id)
            key = Transformer::KeyBuilder.documents_key(res.db_id, res.coll_id)
            @db_interface.delete_from_hash key, [res.doc_name]
            # Now rename keys <info, <emmaping, <amapping, <content, <namespaces to new collection
            @db_interface.rename_key key_builder.info, key_builder_new.info
            @db_interface.rename_key key_builder.elem_mapping_key, key_builder_new.elem_mapping_key
            @db_interface.rename_key key_builder.attr_mapping_key, key_builder_new.attr_mapping_key
            @db_interface.rename_key key_builder.content_key, key_builder_new.content_key
            @db_interface.rename_key key_builder.namespace_key, key_builder_new.namespace_key

            res.coll_id = target_coll_id
          end
        end

        # Method is used to generate SAX events for the given handler using specified document
        # in database.
        # ==== Parameters
        # * +doc_name+ - Name of the document for which the events should be generated
        # * +handler+ - Instance of Nokogiri::SAX::Document
        # ==== Raises
        # Transformer::MappingException - If the specified document does not exist
        def generate_sax_events(doc_name, handler)
          file_id = get_document_id(doc_name)

          if(file_id == nil)
            fail Transformer::MappingException, "Document with name #{doc_name} not found."
            return nil
          end
          @builder = Transformer::KeyBuilder.new(@env_id, @coll_id, file_id)
          @xml_transformer = Transformer::XMLTransformer.new(@db_interface, @builder)
          @xml_transformer.get_document_as_sax(@builder, handler)
        end

        # Get document ID for the given name
        # ==== Parameters
        # * +name+ - Name of the document for which the ID should be retrieved
        # ==== Return value
        # String with ID, nil if no ID exist
        def get_document_id(name)
          doc_id = @db_interface.get_hash_value(@doc_key, name)
          return doc_id
        end

        # Get IDs of all documents in a collection specified during instaciation of this DocumentService
        # ==== Return value
        # Array of document IDs
        def get_all_documents_ids()
          ids = @db_interface.get_all_hash_values(@doc_key)
          ids ||= []
          return ids
        end

        # Get names of all documents in a collection specified during instaciation of this DocumentService
        # ==== Return value
        # Array of document names
        def get_all_documents_names()
          names =  @db_interface.get_all_hash_fields(@doc_key)
          names ||= []
          return names
        end

        # Deletes specified document from the database
        # ==== Parameters
        # * +name+ - Name of the document to be deleted
        def delete_document(name)
          #We have to delete <info, <emapping, <amapping, <content, and field in envId:collId:documents
          doc_id = get_document_id(name)
          return unless doc_id
          @builder = Transformer::KeyBuilder.new(@env_id, @coll_id, doc_id)
          del_keys = [@builder.content_key, @builder.info, @builder.elem_mapping_key, @builder.attr_mapping_key, @builder.namespace_key]
          @db_interface.delete_keys del_keys
          @db_interface.delete_from_hash(@doc_key, [name])
        end

        # Rename specified document if the new name does not already exist
        # ==== Parameters
        # * +old_name+ - Name of the document to be renamed
        # * +name+ - New name for a document
        # ==== Raises
        # Transformer::MappingException - If the rename operation couldn't be completed
        # because the new name already exist or if some internal error occurs.
        def rename_document(old_name, name)
          #Verify that new name isn't already in database
          result = @db_interface.hash_value_exist?(@doc_key, name)
          fail Transformer::MappingException, "Document with such a name already exist." if result
          result = @db_interface.hash_value_exist?(@doc_key, old_name)
          fail Transformer::MappingException, "Cannot rename, document #{old_name} doesn't exist." unless result

          #Delete old enevironment
          old_id = get_document_id(old_name)
          del_res = @db_interface.delete_from_hash(@doc_key, [old_name])
          add_res = @db_interface.add_to_hash_ne(@doc_key, name, old_id)

          #Note: result may obtain some old return values from redis, we have to lookup at the end of result
          fail Transformer::MappingException, "Cannot delete old document's name, rename aborted." if del_res != 1 && !del_res
          fail Transformer::MappingException, "Renaming failed." if add_res != 1 && !add_res
        end

        # Verifies if document with specified name exist in the collection.
        # ==== Parameters
        # * +name+ - Name of the document whose existence should be verified
        # ==== Return value
        # True if document with a given name exist in collection, false otherwise
        def document_exist?(name)
          return @db_interface.hash_value_exist?(@doc_key, name)
        end

        private

        # Method is used to verify if a hash field should be ignored, used with special fields
        # like <iterator> etc. when we need to get all names etc. Will be proably deprected
        def ignore_field?(field_name)#:nodoc:
          return true if field_name[0] == Transformer::KeyBuilder::HASH_SPECIAL_SEPARATOR
          return false
        end

        def logger
          RedXML::Server.logger
        end
      end
    end
  end
end
