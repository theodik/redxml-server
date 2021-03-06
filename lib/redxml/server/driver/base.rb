module RedXML
  module Server
    module Driver
      class Base
        def connection
        end

        ## Keys

        # Returns all keys
        def get_keys # rubocop:disable AccessorMethodName
          fail NotImplementedError
        end

        # Returns string representation of the type of the value at key
        def get_type(key)
          fail NotImplementedError
        end

        # Renames key to new_key
        def rename_key(key, new_key)
          fail NotImplementedError
        end

        # Returns true if a key exists
        def key_exists?(key)
          fail NotImplementedError
        end

        # Delete a key
        def delete_key(key)
          fail NotImplementedError
        end

        ## Strings

        # Set the string value of a key
        #
        # If key already holds a value, it is overwritten.
        def set_string(key, value)
          fail NotImplementedError
        end

        # Get the value of a key
        def get_string(key)
          fail NotImplementedError
        end

        # Append value to a key
        #
        # If key doesnt exist, it is created first and then set to value.
        def append_string(key, value)
          fail NotImplementedError
        end

        # Increment value stored at key by value
        #
        # If key doesnt exists, it is set to 0 and incremented.
        def increment_value(key, value = 1)
          fail NotImplementedError
        end

        # Decrement value stored at key by value
        #
        # If key doesnt exists, it is set to 0 and decremented.
        def decrement_value(key, value = 1)
          fail NotImplementedError
        end

        ## Hashes

        # Store hash at key
        def set_hash(key, hash)
          fail NotImplementedError
        end

        # Returns hash stored at key
        def get_hash(key)
          fail NotImplementedError
        end

        # Sets field in the hash stored at key to value.
        #
        # If key does not exist, a new key holding a hash is created.
        # If field already exists in the hash, it is overwritten.
        def set_value(key, field, value)
          fail NotImplementedError
        end

        # Increments the number stored at field in the hash
        # stored at key by increment.
        # If key does not exist, a new key holding a hash is created.
        # If field does not exist the value is set to 0 before
        # the operation is performed.
        def increment_field(key, field, value = 1)
          fail NotImplementedError
        end

        # Decrements the number stored at field in the hash
        # stored at key by decrement.
        # If key does not exist, a new key holding a hash is created.
        # If field does not exist the value is set to 0 before
        # the operation is performed.
        def decrement_field(key, field, value = 1)
          fail NotImplementedError
        end

        # Returns the value associated with field in the hash stored at key.
        def get_value(key, field)
          fail NotImplementedError
        end

        # Returns all values in the hash stored at key.
        def get_values(key)
          fail NotImplementedError
        end

        # Returns all field names in the hash stored at key.
        def get_fields(key)
          fail NotImplementedError
        end

        # Returns if field is an existing field in the hash stored at key.
        def field_exists?(key, field)
          fail NotImplementedError
        end

        # Removes the specified fields from the hash stored at key.
        # Specified fields that do not exist within this hash are ignored.
        # If key does not exist, it is treated as an empty hash.
        def delete_value(key, field)
          fail NotImplementedError
        end

        # Lists
        # TODO: Is it needed?

        # Sets
        # TODO: Is it needed?
      end
    end
  end
end
