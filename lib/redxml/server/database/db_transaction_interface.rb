require 'redxml/server/database/transaction_manager'
require 'redxml/server/database/context_node'

module RedXML
  module Server
    module Database
      class DBTransactionInterface < DatabaseInterface
        def initialize(driver)
          super
          @tr_manager = TransactionManager.instance
          @transaction = nil
        end

        def transaction_obj
          @transaction
        end

        def add_to_hash(key, hash, overwrite = true)
          return super unless @transaction
          # if is_content? key
          #   hash.each_slice(2) do |field, _val|
          #     node = ContextNode.new(key, field)
          #     @transaction.acquire_lock node, :SU
          #   end
          # end
          super
        end

        def add_to_hash_ne(key, field, value, mapping_service = false)
          super
        end

        def increment_hash(key, field, number, mapping_service = false)
          super
        end

        def delete_from_hash(key, hash_fields)
          return super unless @transaction
          if is_content? key
            hash_fields.each do |field|
              node = ContextNode.new(key, field)
              @transaction.acquire_lock node, :SX
            end
          end
          super
        end

        def get_hash_value(key, field)
          return super unless @transaction
          if is_content? key
            node = ContextNode.new(key, field)
            @transaction.acquire_lock node, :NR
          end
          super
        end

        def get_all_hash_values(key)
          super
        end

        def get_all_hash_fields(key)
          super
        end

        def hash_value_exist?(key, field)
          super
        end

        def add_to_list(key, values)
          super
        end

        def delete_from_list(key, values)
          super
        end

        def increment_string(key)
          super
        end

        def decrement_string(key)
          super
        end

        def rename_key(old_key, new_key)
          super
        end

        def find_keys(pattern = "*")
          super
        end

        def save_hash_entries(key_value_hash, overwrite = true)
          super
        end

        def save_string_entries(*key_string, overwrite)
          super
        end

        def delete_entries(keys)
          super
        end

        def entry_exist?(key)
          super
        end

        def find_value(key)
          super
        end

        def delete_all_keys
          super
        end

        def transaction
          @transaction = @tr_manager.transaction
          super
        end

        def commit
          @tr_manager.release(@transaction)
          @transaction = nil
          super
        end

        private

        def is_content?(mapping_key)
          mapping_key =~ /content/
        end
      end
    end
  end
end

