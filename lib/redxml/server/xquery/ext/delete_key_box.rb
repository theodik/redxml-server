module RedXML
  module Server
    module XQuery
      class DeleteKeyBox
        def initialize
          @key_bean_hash = Hash.new #field - parent_key, value DeleteKeyBean
        end

        def add_delete_key(delete_key, parent_key, parent_children_array, key_builder_str)
          bean = @key_bean_hash[parent_key]
          if bean == nil
            bean = ParentBean.new(parent_key, parent_children_array, key_builder_str)
            @key_bean_hash[parent_key] = bean
          end
          bean.delete_key(delete_key)
        end

        def beans_to_store
          @key_bean_hash.values
        end
      end

      class ParentBean
        attr_reader :parent_key, :key_builder_str

        def initialize(parent_key, parent_children_array, key_builder_str)
          @key_builder_str = key_builder_str
          @parent_key      = parent_key
          @children_hash   = Hash.new
          parent_children_array.each_with_index do |child_str, index|
            @children_hash[child_str] = index
          end
        end

        def delete_key(key)
          @children_hash.delete(key)
        end

        def parent_value
          # children should be ordered TODO check!
          result = ""
          @children_hash.values.sort.each do |index|
            key = @children_hash.key(index)
            unless result.empty?
              result << RedXML::Server::XQuery::Processors::KeyPathProcessor::CHILDREN_SEPARATOR
            end
            result << key
          end
          result
        end
      end
    end
  end
end
