require 'redxml/server/xquery/ext/delete_key_box'

module RedXML
  module Server
    module XQuery
      module Processors
        class DeleteProcessor < KeyPathProcessor
          attr_reader :key_builder

          @@processor_pool = {}

          # rather use static delete_nodes
          def delete_node(key_str)
            if RedXML::Server::Transformer::KeyElementBuilder.element?(key_str)
              key_element_builder = RedXML::Server::Transformer::KeyElementBuilder
                                    .build_from_s(nil, key_str)
              children = get_plainly_children(key_str)
              children.each { |child| delete_node(child) }
              @db.delete_from_hash(@content_hash_key, [key_element_builder.attr, key_str])
            else
              @db.delete_from_hash(@content_hash_key, [key_str])
            end
          end

          def rewrite_parent(parent_key, parent_value)
            @db.add_to_hash(@content_hash_key, [parent_key, parent_value], true)
          end

          def self.delete_nodes(db_interface, extended_keys, _pipelined = true)
            delete_nodes_only(db_interface, extended_keys)
          end

          private

          def self.delete_nodes_only(db_interface, extended_keys)
            delete_box = DeleteKeyBox.new

            extended_keys.each do |extended_key|
              key_builder = extended_key.key_builder
              pool_key = key_builder.to_s
              processor = @@processor_pool[pool_key]
              if processor.nil?
                processor = DeleteProcessor.new(db_interface, key_builder)
                @@processor_pool[pool_key] = processor
              end

              # remove reference of deleted key from his parent
              # so memorize what keys should be deleted and delete in the end all of them
              delete_key = extended_key.key_str
              delete_box.add_delete_key(delete_key, extended_key.parent_key, extended_key.parent_children_array, pool_key)

              # recursively delete node
              processor.delete_node(extended_key.key_str)
            end

            # store new parent contents
            delete_box.beans_to_store.each do |bean|
              processor = @@processor_pool[bean.key_builder_str]
              fail 'not possible' if processor.nil?
              processor.rewrite_parent(bean.parent_key, bean.parent_value)
            end
          end
        end
      end
    end
  end
end
