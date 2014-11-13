module RedXML
  module Server
    module Transformer
      # Class represents an abstraction layer which provides
      # basic functionality to work with Collections.
      # It is possible to create, delete or rename collections and much more.
      class CollectionService
        # Createsnew instance of CollectionService. It's functionality
        # is heavily influenced by the parameters.
        # Using only env_id means that all operations are invoked
        # as if environment with ID env_id invoked them.
        # On the other hand, when coll_id and coll_name are specified
        # all operations are invoked as if collection with
        # such an ID would invoked them.
        # Remember, collections can be nested,
        # so environment creates "root" colletions and
        # those collections can create "child" collections.
        # ==== Parameters
        # * +db_interface+ - An driver object connected to db
        # * +env_id+ - ID of the environment in which operations
        #              will be executed (unless other prameters are set)
        # * +coll_id+ - ID of the collection in which operations
        #               will be executed located in environment with ID env_id
        # * +coll_name+ - Name of the collection in which operations will
        #                 be executed located in environment with ID env_id
        def initialize(db_interface, env_id, coll_id = false, coll_name = false)
          @db_interface = db_interface
          @env_id = env_id
          @coll_id = coll_id
          @coll_name = coll_name
          @env_info = Transformer::KeyBuilder.environment_info(@env_id)
          @certain_coll_key = Transformer::KeyBuilder
                          .child_collections_key(@env_id, @coll_id) if @coll_id
          @certain_coll_key = Transformer::KeyBuilder
                          .collections_key(@env_id) unless @coll_id
        end

        # Creates new collection with a given name
        # in a database and returns it's ID
        # ==== Parameters
        # * +name+ - Name of the collection to be created
        # ==== Return value
        # String with the ID of the created collection
        # ==== Raises
        # MappingException - If collection with such a name already exist
        def create_child_collection(name)
          coll_id = @db_interface.increment_hash(@env_info,
            Transformer::KeyElementBuilder::ITERATOR_KEY, 1)
          result = @db_interface.add_to_hash_ne(@certain_coll_key,
                                                name,
                                                coll_id)
          fail Transformer::MappingException,
               'Collection with such a name already exist.' unless result
          # Now we have to save parent id to hash
          # if we are creating nested collection
          created_coll_info_key = Transformer::KeyBuilder
                                  .collection_info(@env_id, coll_id)
          # Child collection now know id of it's parent
          info = [Transformer::KeyBuilder::NAME_KEY, name]
          # Create <parent_id> only if it has any parent,
          # environment is not a parent
          if @coll_id
            info << Transformer::KeyBuilder::PARENT_ID_KEY << @coll_id
          end
          @db_interface.add_to_hash(created_coll_info_key, info, true)
          coll_id
        end

        # Deletes collection with a given name from the database,
        # if collection with such a name does not exist method will return.
        # ==== Parameters
        # * +name+ - Name of the collection to be deleted
        def delete_child_collection(name)
          # Delete collection = delete all documents in it and
          # then delete field in envId:collections key
          coll_id = nil
          begin
            coll_id = get_child_collection_id(name)
          rescue Transformer::MappingException => ex
            ex.message
            return
          end

          service = Transformer::DocumentService.new(@db_interface, @env_id, coll_id)
          service.get_all_documents_names.each do |doc|
            service.delete_document(doc)
          end
          Transformer::CollectionService
            .new(@db_interface, @env_id, coll_id)
            .delete_all_child_collections

          @db_interface.delete_from_hash(@certain_coll_key, [name])
          # We have to delete all keys of collection,
          # e.g. <info, <documents, <collections
          coll_info = Transformer::KeyBuilder.collection_info(@env_id, coll_id)
          doc_key = Transformer::KeyBuilder.documents_key(@env_id, coll_id)
          keys = Transformer::KeyBuilder.child_collections_key(@env_id, coll_id)
          del_keys = [coll_info, doc_key, keys]
          @db_interface.delete_keys(del_keys)
        end

        # Deletes all collections in a database.
        def delete_all_child_collections
          all_names = get_all_child_collections_names
          all_names.each do |name|
            delete_child_collection(name)
          end
        end

        # Returns ID for the collection specified by name.
        # ==== Parameters
        # * +name+ - Name of the collection for which the ID should be retrieved
        # ==== Return value
        # String with the ID of the collection
        # ==== Raises
        # MappingException - If collection with such a name does not exist
        def get_child_collection_id(name)
          coll_id = @db_interface.get_hash_value(@certain_coll_key, name)
          fail Transformer::MappingException,
            "Collection with such a name doesn't exist." unless coll_id
          coll_id
        end

        # Returns IDs of all collections in the database
        # ==== Return value
        # Array with IDs of all collections
        def get_all_child_collections_ids
          ids =  @db_interface.get_all_hash_values(@certain_coll_key)
          ids ||= []
          ids
        end

        # Returns names of all collections in the database
        # ==== Return value
        # Array with names of all collections
        def get_all_child_collections_names
          # Remember there are fields begining with "<" which has to be excluded
          names =  @db_interface.get_all_hash_fields(@certain_coll_key)
          names ||= []
          names
        end

        # Returns ID of the parent of collection which is using
        # this instance of Collection
        # ==== Return value
        # String with ID of the parent collection or nil if there is no parent
        def get_parent_id
          result = nil
          # if coll_id is false, then collection is
          # used by environment so no parent
          if @coll_id
            info = Transformer::KeyBuilder.collection_info(@env_id, @coll_id)
            result = @db_interface.get_hash_value(info,
                                         Transformer::KeyBuilder::PARENT_ID_KEY)
          end
          result
        end

        # Returns name of the parent of collection which is using
        # this instance of Collection
        # ==== Return value
        # String with name of the parent collection or nil if there is no parent
        def get_parent_name
          parent_id = get_parent_id
          return nil unless parent_id
          temp_coll_service = self.class.new(@db_interface, @env_id, parent_id)
          temp_coll_service.get_collection_name
        end

        # Returns ID of the collection, which is using this
        # instance of Collection
        # ==== Return value
        # String with the ID of the colletion which uses this
        # instance of Collection or nil if
        # this service is used by Environment
        def get_collection_id
          @coll_id
        end

        # Returns name of the collection which is using this
        # instance of Collection
        # ==== Return value
        # String with name of the collection or nil if no collection is using
        # this instance of Collection
        def get_collection_name()
          result = nil
          # if coll_id is false, than collection_service is used by environment
          if @coll_id
            info = Transformer::KeyBuilder.collection_info(@env_id, @coll_id)
            result = @db_interface.get_hash_value(info,
                                              Transformer::KeyBuilder::NAME_KEY)
          end
          result
        end

        # Rename collection = change it's name, not ID. When called from
        # Environment root collections are searched to be renamed.
        # If Collection is using this service,
        # then child collections are searched to be renamed.
        # ==== Parameters
        # * +old_name+ - Name of the collection which should be renamed
        # * +name+ - New name for the collection
        # ==== Raises
        # MappingException - If collection with old_name does not exist or
        #                    if there already is collection with name parameter
        #                    as it's name
        def rename_child_collection(old_name, name)
          # Verify that new name isn't already in database
          result = @db_interface.hash_value_exist?(@certain_coll_key, name)
          fail Transformer::MappingException,
            'Collection with such a name already exist.' if result
          result = @db_interface.hash_value_exist?(@certain_coll_key, old_name)
          fail Transformer::MappingException,
            "Cannot rename, collection #{old_name} doesn't exist." unless result

          # Delete old enevironment
          old_id = get_child_collection_id(old_name)
          result = [
            @db_interface.delete_from_hash(@certain_coll_key, [old_name]),
            @db_interface.add_to_hash_ne(@certain_coll_key, name, old_id)
          ]
          # Note: result may obtain some old return values from redis,
          # we have to lookup at the end of result
          unless result[-1]
          fail Transformer::MappingException,
             "Cannot delete old collection's name, rename aborted."
          end
          unless result[-2]
            fail Transformer::MappingException, 'Renaming failed.'
          end
        end

        # Verifies if collection with a given name exist
        # (under the certain Environment or Collection
        # based on which is using this service)
        # ==== Return value
        # True if the collection with given name exist, False otherwise
        def child_collection_exist?(name)
          @db_interface.hash_value_exist?(@certain_coll_key, name)
        end

        def logger
          RedXML::Server.logger
        end
      end
    end
  end
end
