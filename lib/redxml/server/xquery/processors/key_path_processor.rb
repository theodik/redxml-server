require 'redxml/server/xquery/ext/extended_key'

module RedXML
  module Server
    module XQuery
      module Processors
        class KeyPathProcessor
          CHILDREN_SEPARATOR = Transformer::XMLTransformer::DESC_SEPARATOR

          attr_reader :key_builder, :mapping_service, :content_hash_key, :xml_transformer

          # key - Key object
          def initialize(db_interface, key_builder)
            @db          = db_interface
            @key_builder = key_builder

            # init xml transformer
            @xml_transformer = Transformer::XMLTransformer.new(@db, @key_builder)

            # load file hashes
            @mapping_service = @xml_transformer.mapping_service
            @content_hash_key = key_builder.content_key
            info_hash = @db.find_value(key_builder.info)

            # load root key - KeyElementBuilder object
            @root_key = Transformer::KeyElementBuilder.new(key_builder, info_hash["root"])
          end

          def valid_elem?(incomming) #return true/false
            incomming.kind_of?(ExtendedKey)
          end

          def get_text(extended_key)
            return extended_key if extended_key.kind_of?(String)
            get_texts(extended_key).join
          end

          def get_descendant_texts(extended_key)
            results = [ get_text(extended_key) ]
            descendants = get_desc_elements(extended_key)
            descendants.each do |desc|
              results << get_text(desc)
            end
            results
          end

          def get_node_content(extended_key)
            get_node(extended_key).content
          end


          def get_children_elements(extended_key, match_elem_name="*")
            key_array = []

            # get element name id from mapping service
            match_elem_id = match_elem_name
            match_elem_id = get_elem_index(match_elem_name) if match_elem_name != "*"

            return [] if !match_elem_id

            # get children in plain text form
            children_array = get_children_plain(extended_key)
            if children_array == nil
              # extended_key is DOCUMENT key -> root element is the only child
              return [ ExtendedKey.build_from_key(@root_key, nil, nil) ]
            end

            # filter out element-nodes with given match_elem_name
            # create ExtendedKey objects for all filtered elements
            children_array.each do |key_str|
              if Transformer::KeyElementBuilder.element?(key_str)
                new_key = Transformer::KeyElementBuilder \
                  .build_from_s(@key_builder, key_str)
                # check match_elem_name
                if(match_elem_id == "*" || new_key.elem_id == match_elem_id)
                  new_extended_key = ExtendedKey.build_from_key(new_key, \
                                                                extended_key.key_str, \
                                                                children_array)
                  key_array << new_extended_key
                end
              end
            end
            key_array
          end

          def get_descendant_elements(extended_key, match_elem_name="*")
            match_elem_id = match_elem_name
            match_elem_id = get_elem_index(match_elem_name) if match_elem_name != "*"

            return [] if !match_elem_id

            all_keys = get_desc_elements(extended_key)
            key_array = []
            all_keys.each do |new_key|
              if match_elem_id == "*" || new_key.key_element_builder.elem_id == match_elem_id
                key_array << new_key
              end
            end

            key_array
          end

          def get_node(extended_key)
            return extended_key if extended_key.kind_of?(String)
            @xml_transformer.get_node(extended_key.key_element_builder)
          end

          def get_attribute(extended_key, attr_name)
            attr_hash = @xml_transformer.get_attributes(extended_key.key_element_builder, false) #TODO resolve with Pavel
            # puts "getting attribute has from XMLTransformer: #{attr_hash.inspect}"
            return nil if !attr_hash
            attr_hash[get_attr_index(attr_name)]
          end

          def get_children_plain(extended_key)#String Array
            return nil if extended_key.type == ExtendedKey::DOCUMENT
            get_plainly_children(extended_key.key_element_builder.to_s)
          end

          protected

          attr_writer :content_hash_key

          private

          def get_desc_elements(extended_key)
            start_key_array = []
            start_key_array.concat(get_children_elements(extended_key))

            all_round_keys = []
            all_round_keys.concat(start_key_array)
            start_key_array.each do |start_key|
              all_round_keys.concat(get_desc_elements(start_key))
            end

            all_round_keys
          end

          def get_plainly_children(key_str)
            list_str = @db.get_hash_value(@content_hash_key, key_str)
            return [] if list_str == nil
            # raise StandardError, "wrong key or content hash_key, nil found instead of descendants, hash_key: #{@content_hash_key}, key: #{key_str}"
            values = list_str.split(CHILDREN_SEPARATOR)
            values
          end

          def get_texts(extended_key)
            texts = []
            key_array = get_children_plain(extended_key)
            return [""] if key_array.nil?
            key_array.each do |key_str|
              case Transformer::KeyElementBuilder.text_type(key_str)
              when XML::TextContent::PLAIN, XML::TextContent::CDATA
                t = @db.get_hash_value(@content_hash_key, key_str)
                texts << t
              end
            end
            texts
          end

          def get_elem_index(elem_name)
            @mapping_service.map_elem_name(elem_name)
          rescue Transformer::MappingException
            nil
          end

          def get_attr_index(attr_name)
            @mapping_service.map_attr_name(attr_name)
          rescue Transformer::MappingException
            nil
          end
        end
      end
    end
  end
end
