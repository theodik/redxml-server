module RedXML
  module Server
    module Database
      class DBTransactionInterface < DBInterface
        def initialize(driver)
          super
        end

        def add_to_hash(key, hash, overwrite = true)
          super
        end

        def add_to_hash_ne(key, field, value, mapping_service = false)
          super
        end

        def increment_hash(key, field, number, mapping_service = false)
          super
        end

        def delete_from_hash(key, hash_fields)
          super
        end

        def get_hash_value(key, field)
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

        def delete_all_keys()
          super
        end

        def commit
          super
        end

        def transaction
          super
        end
      end
    end
  end
end

