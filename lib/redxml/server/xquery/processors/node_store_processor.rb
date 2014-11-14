module RedXML
  module Server
    module XQuery
      module Processors
        class NodeStoreProcessor
          def initialize(mapping_service, content_hash_key)
            @content_hash_key = content_hash_key
            @mapping_service = mapping_service
            @db = @mapping_service.db_interface
          end

          def save_node(nokogiri_node, key_element_builder)
            # save attributes
            save_attributes(nokogiri_node, key_element_builder)

            # save children
            elem_id_hash = {}
            text_order = 0
            comment_order = 0
            cdata_order = 0
            children_keys = []
            nokogiri_node.children.each do |child|
              child_key = nil
              if child.element?
                elem_id = get_elem_id(child.name)
                order = elem_id_hash[elem_id]
                order = 0 unless order
                child_key = RedXML::Server::Transformer::KeyElementBuilder
                  .build_from_s(key_element_builder.key_builder, key_element_builder.elem(elem_id, order))
                # child_key = key_element_builder.elem(elem_id, order)
                elem_id_hash[elem_id] = (order + 1)

                # save this child node recursively
                save_node(child, child_key)
              else
                if child.text?
                  child_key = key_element_builder.text(text_order)
                  text_order += 1

                elsif child.comment?
                  child_key = key_element_builder.comment(comment_order)
                  comment_order += 1

                elsif child.cdata?
                  child_key = key_element_builder.comment(cdata_order)
                  cdata_order += 1

                else
                  fail "not supported other sort of child: #{child.class}"
                end

                # save text/comment/cdata to db
                @db.add_to_hash(@content_hash_key, [child_key, child.text])
              end

              # add child to children keys
              children_keys << child_key.to_s
            end

            # save children_keys to this nodes content
            @db.add_to_hash(@content_hash_key, [key_element_builder.to_s, children_keys.join(KeyPathProcessor::CHILDREN_SEPARATOR)])
          end

          def save_attributes(nokogiri_node, key_element_builder)
            # map attribute names to IDs
            attributes = {}
            nokogiri_node.attributes.each do |key, value|
              attributes[get_attr_id(key)] = value
            end
            # store attributes do database
            unless attributes.empty?
              @db.add_to_hash(@content_hash_key,
                              [key_element_builder.attr,
                               attributes.to_a
              .flatten
              .join(RedXML::Server::Transformer::XMLTransformer::ATTR_SEPARATOR)
              ]
                             )
            end
          end

          def get_attr_id(attr_name)
            @mapping_service.map_attr_name(attr_name)
          rescue RedXML::Server::Transformer::MappingException
            @mapping_service.create_attr_mapping(attr_name)
          end

          def get_elem_id(elem_name)
            @mapping_service.map_elem_name(elem_name)
          rescue RedXML::Server::Transformer::MappingException
            @mapping_service.create_elem_mapping(elem_name)
          end
        end
      end
    end
  end
end
