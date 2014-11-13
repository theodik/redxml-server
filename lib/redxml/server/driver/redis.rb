module RedXML
  module Server
    module Driver
      class Redis < Base
        def initialize(options = {})
          begin
            require 'redis'
          rescue LoadError
            raise LoadError, "RedXML's redis driver is unable " \
                  "to load `redis`, please install the gem and " \
                  "add `gem 'redis'` to your Gemfile if you are using bundler."
          end
          options = options.dup
          setup_options!(options)
          @redis = ::Redis.new(options)
        end

        def connection
          @redis
        end

        ## Keys

        # Returns all keys
        def get_keys # rubocop:disable AccessorMethodName
          @redis.keys '*'
        end

        def find_keys(pattern = '*')
          @redis.keys pattern
        end

        # Returns string representation of the type of the value at key
        def get_type(key)
          @redis.type key
        end

        # Renames key to new_key
        def rename_key(key, new_key)
          @redis.rename key, new_key
        end

        # Returns true if a key exists
        def key_exists?(key)
          @redis.exists key
        end

        # Delete a key
        def delete_key(key)
          @redis.del key
        end

        # Delete a keys
        def delete_keys(keys)
          @redis.del *keys
        end

        ## Strings

        # Set the string value of a key
        #
        # If key already holds a value, it is overwritten.
        def set_string(key, value)
          @redis.set key, value
        end

        def set_multiple_strings(*args)
          @redis.mset *args
        end

        def set_multiple_strings_ne(*args)
          @redis.msetnx *args
        end

        # Get the value of a key
        def get_string(key)
          @redis.get key
        end

        # Append value to a key
        #
        # If key doesnt exist, it is created first and then set to value.
        def append_string(key, value)
          @redis.append key, value
        end

        # Increment value stored at key by value
        #
        # If key doesnt exists, it is set to 0 and incremented.
        def increment_value(key, value = 1)
          @redis.incrby key, value
        end

        # Decrement value stored at key by value
        #
        # If key doesnt exists, it is set to 0 and decremented.
        def decrement_value(key, value = 1)
          @redis.decrby key, value
        end

        ## Hashes

        # Store hash at key
        def set_hash(key, hash)
          @redis.hmset key, *hash.flatten
        end

        # Returns hash stored at key
        def get_hash(key)
          @redis.hgetall(key)
        end

        # Sets field in the hash stored at key to value.
        #
        # If key does not exist, a new key holding a hash is created.
        # If field already exists in the hash, it is overwritten.
        def set_value(key, field, value)
          @redis.hset key, field, value
        end

        # Sets field in the hash stored at key to value.
        #
        # Sets only if field does not yet exist.
        # If key does not exist, a new key holding
        # a hash is created. If field already exists,
        # this operation has no effect.
        def set_value_ne(key, field, value)
          @redis.hsetnx key, field, value
        end

        # Increments the number stored at field in the hash
        # stored at key by increment.
        # If key does not exist, a new key holding a hash is created.
        # If field does not exist the value is set to 0 before
        # the operation is performed.
        def increment_field(key, field, value = 1)
          @redis.hincrby key, field, value
        end

        # Decrements the number stored at field in the hash
        # stored at key by decrement.
        # If key does not exist, a new key holding a hash is created.
        # If field does not exist the value is set to 0 before
        # the operation is performed.
        def decrement_field(key, field, value = 1)
          @redis.hincrby key, field, -value
        end

        # Returns the value associated with field in the hash stored at key.
        def get_value(key, field)
          @redis.hget key, field
        end

        # Returns all values in the hash stored at key.
        def get_values(key)
          @redis.hvals key
        end

        # Returns all field names in the hash stored at key.
        def get_fields(key)
          @redis.hkeys key
        end

        # Returns if field is an existing field in the hash stored at key.
        def field_exists?(key, field)
          @redis.hexists key, field
        end

        # Removes the specified fields from the hash stored at key.
        # Specified fields that do not exist within this hash are ignored.
        # If key does not exist, it is treated as an empty hash.
        def delete_value(key, field)
          @redis.hdel key, field
        end

        # Lists

        # Append one or multiple values to a list
        #
        # Insert all the specified values at the tail of the list stored at key.
        # If key does not exist, it is created as empty list before performing
        # the push operation. When key holds a value that is not a list,
        # an error is returned.
        def insert_value(key, value)
          @redis.rpush key, value
        end

        # Remove elements from a list
        def remove_value(key, value)
          @redis.lrem key, 0, value
        end

        def list_length(key)
          @redis.llen key
        end

        def list_range(key, from, to)
          @redis.lrange key, from, to
        end

        def transaction(&block)
          @redis.multi(&block)
        end

        def flush_all
          @redis.flushall
        end

        private

        def setup_options!(options) # :nodoc:
          keys = %i(host port db url)
          options.select! { |k,_| keys.include? k }
        end
      end
    end
  end
end
