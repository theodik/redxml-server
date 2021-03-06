module RedXML
  module Server
    module Transformer
      # This class is used to create keys according to our proprietary mapping.
      # It works with environments, collections and documents. It supports
      # smooth transation into KeyElementBuilder using KeyBuilder#root
      # method so you can immediately work with elements.
      class KeyBuilder
        # Separator of levels (Environment, Collection, Document) in the key
        SEPARATOR = ":"

        # Field of the iterator, which is used to create new ids
        ITERATOR_KEY = "<iterator>"
        # Field with the id of the parent of the certain collection
        PARENT_ID_KEY = "<parent_id>"
        # Field with the name of the parent of the certain collection
        NAME_KEY = "<name>"

        # Holds a key to hash of all environments
        attr_reader :environment_key
        # Holds a key to hash of all collections under the certain environment
        # (given as init parameter env_id)
        attr_reader :collection_key
        # Holds a key to hash of all documents under the certain collection
        # (given as init parameter coll_id)
        attr_reader :document_key

        # Creates new instance of KeyBuilder
        # using ids of environment, collection and document
        # ==== Parameters
        # * +env_id+ - Id of a certain environment
        # * +coll_id+ - Id of a certain collection
        # * +doc_id+ - Id of a certain document
        def initialize(env_id, coll_id, doc_id)
          @env_id = env_id
          @coll_id = coll_id
          @doc_id = doc_id

          @environment_key = @env_id
          @collection_key = "#{@environment_key}#{SEPARATOR}#{@coll_id}"
          @document_key = "#{@collection_key}#{SEPARATOR}#{@doc_id}"
        end

        # Creates String with the key pointing to hash with all environments
        # ==== Return value
        # String of the key
        def self.environments_key()
          "environments"
        end

        # Creates String with the key pointing to hash with
        # all collections under given environment
        # ==== Parameters
        # * +env_id+ - String (or something which responds to to_s like Integer)
        #              with the environment id
        # ==== Return value
        # String of the key
        def self.collections_key(env_id)
          "#{env_id}#{SEPARATOR}collections"
        end

        # Creates String with the key pointing to hash with
        # all documents under given environment&gt;collection
        # ==== Parameters
        # * +env_id+ - String (or something which responds to to_s like Integer)
        #              with the environment id
        # * +coll_id+ -String (or something which responds to to_s like Integer)
        #               with the collection id
        # ==== Return value
        # String of the key
        def self.documents_key(env_id, coll_id)
          "#{env_id}#{SEPARATOR}#{coll_id}#{SEPARATOR}documents"
        end

        # Creates String with the key pointing to hash with
        # all collections under given environment&gt;collection
        # ==== Parameters
        # * +env_id+ - String (or something which responds to to_s like Integer)
        #              with the environment id
        # * +coll_id+ -String (or something which responds to to_s like Integer)
        #              with the collection id
        # ==== Return value
        # String of the key
        def self.child_collections_key(env_id, coll_id)
          "#{env_id}#{SEPARATOR}#{coll_id}#{SEPARATOR}collections"
        end

        # Creates new instance of KeyBuilder from the given string.
        # ==== Parameters
        # * +key_str+ - String of the valid key
        # ==== Return value
        # KeyBuilder which holds environment, collection and document id
        # ==== Raises
        # ArgumentError - When key_str is not a valid key
        def self.build_from_s(key_str)
          key_split = key_str.split(SEPARATOR)
          if key_split.length < 3
            fail ArgumentError, "#{key_str} cannot be parsed to Key. " \
                  "Simply said: not enough '#{SEPARATOR}' delimiters."
          end
          #There can be keys like "1:2:3<info"
          split = key_split[2].split("<")
          new(key_split[0], key_split[1], split[0])
        end

        # Creates String with the key pointing to hash
        # with information about document
        # ==== Return value
        # String of the key
        def info
          "#{@document_key}<info"
        end

        # Creates String with the key pointing to hash with information
        # about certain collection based on parameters
        # ==== Return value
        # String of the key
        def self.collection_info(env_id, coll_id)
          "#{env_id}#{SEPARATOR}#{coll_id}<info"
        end

        # Creates String with the key pointing to hash with information
        # about certain collection (basedon init parameters)
        # ==== Return value
        # String of the key
        def collection_info()
          "#{@env_id}#{SEPARATOR}#{@coll_id}<info"
        end

        # Creates String with the key pointing to hash with information
        # about environment based on env_id
        # ==== Return value
        # String of the key
        def self.environment_info(env_id)
          "#{env_id}<info"
        end

        # Creates String with the key pointing to hash with information
        # about environment based on init parameters
        # ==== Return value
        # String of the key
        def environment_info()
          "#{@env_id}<info"
        end

        # Creates String with the key pointing to hash which contains iterator
        # field (environment ids are generated from it)
        # ==== Return value
        # String of the key
        def self.env_iterator_key()
          "info"
        end

        # Creates String with the key pointing to hash
        # with mapping of elements into ids
        # ==== Return value
        # String of the key
        def elem_mapping_key()
          "#{@document_key}<emapping"
        end

        # Creates String with the key pointing to hash
        # with mapping of attributes into ids
        # ==== Return value
        # String of the key
        def attr_mapping_key()
          "#{@document_key}<amapping"
        end

        # Creates String with the key pointing to hash
        # with content of the document
        # ==== Return value
        # String of the key
        def content_key()
          "#{@document_key}<content"
        end

        # Creates String with the key pointing to the hash
        # with all declared namespaces of XML
        # document
        # ==== Return value
        # String of the key
        def namespace_key()
          "#{@document_key}<namespaces"
        end

        # Creates new instance of KeyElementBuilder using given root_id.
        # Environment, collection and document is based on the inner
        # state of this class.
        # ==== Parameters
        # * +root_id+ -String (or something which responds to to_s like Integer)
        #              with the root id
        # ==== Return value
        # KeyElementBuilder
        def root(root_id)
          KeyElementBuilder.new(self, "#{root_id}")
        end

        # Creates new instance of KeyElementBuilder using given key_str.
        # Environment, collection and document is based on the inner
        # state of this class.
        # ==== Parameters
        # * +root_id+ -String (or something which responds to to_s like Integer)
        #              with the element id
        # ==== Return value
        # KeyElementBuilder
        def key_elem(key_str)
          KeyElementBuilder.build_from_s(self, key_str)
        end

        # Creates String with the key of this KeyBuilder instance which can be
        # used for KeyBuilder#build_from_s method
        # later on.
        # ==== Return value
        # String of the key
        #
        # ==== Examples
        # Result o this method:
        #    builder =  Transformer::KeyBuilder.new("1", "2", "3")
        #    puts builder #1:2:3
        def to_s()#:String
          @document_key
        end
      end
    end
  end
end
