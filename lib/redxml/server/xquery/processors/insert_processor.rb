module RedXML
  module Server
    module XQuery
      module Processors
        class InsertProcessor
          def initialize(path_solver)
            @path_solver             = path_solver
            @key_path_processor_pool = {}
          end

          # items as array of ExpressionHandles and location as ExtendedKey
          def insert_nodes(items, location, target = :TARGET_INTO_LAST, _pipelined = true, contexts = [])
            @location_path_processor = @path_solver.path_processor
            @db                      = @path_solver.db_interface
            @content_hash_key        = @location_path_processor.content_hash_key
            @node_store_processor    = NodeStoreProcessor.new(@location_path_processor.mapping_service,
                                                              @content_hash_key)

            insert_nodes_only(items, location, target, contexts)
          end

          private

          # expr handle, extended key
          def insert_nodes_only(items, location, target, contexts)
            # sort items the way they should be stored
            # so for BEFORE, INTO and AS LAST INTO (which are the same) we dont need to sort anything
            # for AFTER and AS FIRST INTO should be sorted reversely because we are going to insert them sequentially
            #  - always AFTER the location or AS FIRST  in the location
            reverse_specific_items = proc do |item_array, specific_target|
              case specific_target
              when :TARGET_AFTER, :TARGET_INTO_FIRST
                item_array.reverse!
              end
            end
            reverse_specific_items.call(items, target)

            items.each do |item|
              case item.type
                # adding relative or previously loaded var
              when 'RelativePathExpr', 'VarRef'
                extended_keys_to_insert = []
                contexts.each do |context|
                  case item.type
                  when 'RelativePathExpr'
                    extended_keys_to_insert.concat(@path_solver.solve(item, context))
                  when 'VarRef'
                    extended_keys_to_insert.concat(context.variables[item.var_name])
                  else
                    fail 'impossible'
                  end
                end
                reverse_specific_items.call(extended_keys_to_insert, target)
                add_elements(extended_keys_to_insert, location, target)

                # adding constructor
              when 'CompAttrConstructor'
                case target
                when :TARGET_BEFORE, :TARGET_AFTER
                  add_attribute(item, Transformer::KeyElementBuilder.build_from_s(
                    location.key_builder, location.parent_key)
                               )
                else
                  add_attribute(item, location.key_element_builder)
                end

              when 'DirElemConstructor'
                contexts.each do |context|
                  add_node(item.nokogiri_node(@path_solver, context), location, target)
                end

              when 'StringLiteral'
                contexts.each do |_context|
                  add_text(item.text, location, target)
                end
              end
            end
          end

          def add_elements(extended_keys, location_extended_key, target)
            extended_keys.each do |extended_key|
              # item key path processor, mapping service
              # necessary for each item (extended_key) since they can be from different XML document
              pool_key = extended_key.key_builder
              item_key_path_processor = @key_path_processor_pool[pool_key.to_s]
              unless item_key_path_processor
                item_key_path_processor = KeyPathProcessor.new(@db, pool_key)
                @key_path_processor_pool[pool_key.to_s] = item_key_path_processor
              end

              # retrieve the whole xml node (Nokogiri)
              root_node = item_key_path_processor.get_node(extended_key)

              # add this node to the right spot in location document
              add_node(root_node, location_extended_key, target)
            end
          end

          def add_node(root_node, location_extended_key, target)
            # location elem name and id
            elem_id = location_extended_key.key_element_builder.elem_id

            # inserted elem name, retrieve (or generate) its id
            item_elem_name = root_node.name
            item_elem_id = @node_store_processor.get_elem_id(item_elem_name)

            # save the new node to db according target
            case target
            when :TARGET_BEFORE, :TARGET_AFTER
              parent_key = location_extended_key.parent_key
              parent_children_array = location_extended_key.parent_children_array
              location_key = location_extended_key.key_element_builder
              location_key_index = nil # will be found in parent_children_array
              max_order = -1
              parent_children_array.each_with_index do |key_str, index|
                elem_builder = RedXML::Server::Transformer::KeyElementBuilder
                  .build_from_s(location_extended_key.key_builder, key_str)

                # set order of new node
                if elem_builder.elem_id == item_elem_id
                  actual_order = elem_builder.order
                  max_order = actual_order if actual_order > max_order
                end

                # find sibling
                location_key_index = index if key_str == location_key.to_s
              end

              # prepare the right order for new elem insertion
              order = max_order + 1

              # new key for this new inserted elem
              new_key = RedXML::Server::Transformer::KeyElementBuilder
                .build_from_s(location_key.key_builder, location_key.parent)
                .elem!(item_elem_id, order)

              # order and location key index and new key prepared for BEFORE and AFTER insertion
              # perform insertion
              # insert in parent children array in the right place and save to db
              insertion_index = location_key_index
              insertion_index += 1 if target == :TARGET_AFTER

              # insert
              parent_children_array.insert(insertion_index, new_key.to_s)
              @db.add_to_hash(@content_hash_key,
                              [parent_key, parent_children_array.join(KeyPathProcessor::CHILDREN_SEPARATOR)]
                             )

              # insert recursively all descendants of this newly stored new_key (inserted element)
              @node_store_processor.save_node(root_node, new_key)
            else
              # insert into ...
              location_key   = location_extended_key.key_element_builder
              children_array = @location_path_processor.get_children_plain(location_extended_key)

              # generate item key
              elem_id_hash = {}
              max_order = -1
              children_array.each do |key_str|
                if RedXML::Server::Transformer::KeyElementBuilder.element?(key_str)
                  elem_builder = RedXML::Server::Transformer::KeyElementBuilder
                    .build_from_s(location_extended_key.key_builder, key_str)

                  # set order of new node
                  if elem_builder.elem_id == item_elem_id
                    actual_order = elem_builder.order
                    max_order = actual_order if actual_order > max_order
                  end
                end
              end

              # prepare order
              order = max_order + 1

              # new key for this new inserted elem
              new_key = RedXML::Server::Transformer::KeyElementBuilder
                .build_from_s(location_key.key_builder, location_key.to_s)
                .elem!(item_elem_id, order)

              # insert item key to the beginning or to the end of the array and save
              # decide according target and insert
              if target == :TARGET_INTO_FIRST
                children_array.insert(0, new_key.to_s)
              else
                children_array << new_key.to_s
              end

              # store new children
              @db.add_to_hash(@content_hash_key,
                              [location_key.to_s,
                               children_array.join(KeyPathProcessor::CHILDREN_SEPARATOR)]
                             )

              # insert recursively all descendants of this newly stored new_key (inserted element)
              @node_store_processor.save_node(root_node, new_key)
            end
          end

          def add_text(text, location_extended_key, target)
            # location elem name and id
            elem_id = location_extended_key.key_element_builder.elem_id

            # save the new text to db according target
            case target
            when :TARGET_BEFORE, :TARGET_AFTER
              parent_key = location_extended_key.parent_key
              parent_children_array = location_extended_key.parent_children_array
              location_key = location_extended_key.key_element_builder
              location_key_index = nil # will be found in parent_children_array
              max_order = -1
              parent_children_array.each_with_index do |key_str, index|
                # set order of new text node
                if RedXML::Server::Transformer::KeyElementBuilder.text?(key_str)
                  actual_order = RedXML::Server::Transformer::KeyElementBuilder.text_order(key_str)
                  max_order = actual_order if actual_order > max_order
                end

                # find sibling
                location_key_index = index if key_str == location_key.to_s
              end

              # init order
              order = max_order + 1

              # new key for this new inserted elem
              new_key = RedXML::Server::Transformer::KeyElementBuilder
                .build_from_s(location_key.key_builder, location_key.parent)
                .text(order)

              # order and location key index and new key prepared for BEFORE and AFTER insertion
              # perform insertion
              # insert in parent children array in the right place and save to db
              insertion_index = location_key_index
              insertion_index += 1 if target == :TARGET_AFTER

              # insert
              parent_children_array.insert(insertion_index, new_key)
              @db.add_to_hash(@content_hash_key,
                              [parent_key, parent_children_array.join(KeyPathProcessor::CHILDREN_SEPARATOR)]
                             )

              # save text content
              @db.add_to_hash(@content_hash_key, [new_key, text])
            else
              # insert into ...
              location_key = location_extended_key.key_element_builder
              children_array = @location_path_processor.get_children_plain(location_extended_key)

              # generate text key
              max_order = -1
              children_array.each do |key_str|
                # set order of new text node
                if RedXML::Server::Transformer::KeyElementBuilder.text?(key_str)
                  actual_order = Transformer::KeyElementBuilder.text_order(key_str)
                  max_order = actual_order if actual_order > max_order
                end
              end

              # init order
              order = max_order + 1

              # new key for this new inserted text
              new_key = RedXML::Server::Transformer::KeyElementBuilder
                .build_from_s(location_key.key_builder, location_key.to_s)
                .text(order)

              # insert item key to the beginning or to the end of the array and save
              # decide according target and insert
              if target == :TARGET_INTO_FIRST
                children_array.insert(0, new_key)
              else
                children_array << new_key
              end

              # store new children
              @db.add_to_hash(@content_hash_key,
                              [location_key.to_s, children_array.join(KeyPathProcessor::CHILDREN_SEPARATOR)]
                             )

              # store text value
              @db.add_to_hash(@content_hash_key, [new_key, text])
            end
          end

          def add_attribute(attr_expr, key_element_builder)
            # prepare new attr name and value
            attr_name = attr_expr.attr_name
            attr_value = attr_expr.attr_value

            # get xml_transformer
            xml_transformer = @location_path_processor.xml_transformer

            # retrieve new attr_name's ID
            attr_id = @node_store_processor.get_attr_id(attr_name)

            # get attribute hash
            attr_hash = xml_transformer.get_attributes(key_element_builder, false)

            # save new attribute to that hash
            attr_hash[attr_id] = attr_value

            # save that back to database
            attrs_plain = attr_hash.to_a.flatten.join(RedXML::Server::Transformer::XMLTransformer::ATTR_SEPARATOR)

            @db.add_to_hash(@content_hash_key, [key_element_builder.attr, attrs_plain], true)
          end
        end
      end
    end
  end
end
