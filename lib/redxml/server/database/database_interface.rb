module RedXML
  module Server
    module Database
      class DatabaseInterface
        def initialize(driver)
          @driver = driver
        end

        #WORKING WITH HASHES
        #redis.hmset - params: key, *field_value_pairs - rewrites fields, as many pairs we want
        #redis.hmget - params: key, *fields - get all values from all fields as array
        #redis.hdel - params: key, *fields - delete all the given fields
        #redis.hsetnx - params: key, field, value - !!!only one field at a time, set field only if the field does not exist

        # Saves a given array in a database as a hash under a given key, example: ["key", "value"] >> {"key" => "value"}
        # Note: There is probably some concurrency problem with hsetnx, it is very well hidden, for the time being
        # use overwrite=true
        def add_to_hash(key, hash, overwrite = true)
          return if hash.empty?
          if overwrite
            @driver.set_hash(key, hash)
          else
            fields_only = []
            values_only = []
            (hash.length).times do |x|
              fields_only << hash[x] if x % 2 == 0
              values_only << hash[x] if x % 2 != 0
            end
            #Now we have fields and values apart
            fields_only.each_with_index do |field, index|
              @driver.set_value_ne key, field, values_only[index] #set value only if field does not exist
              #TODO may no work in some very rare cases, i still don't fully understand how is this possible
              # probably some concurrency problem with Redis
              #  val = get_hash_value(key, field)
              #  puts "Saved value: #{val}"
            end
          end
        end

        # Add value to hash field if the field does not exist yet, returns true or false
        # mapping_service is special parameter MappingService during transactions. During transaction all
        # the commands are processed at the end, but mapping_service cannot wait and has to map name immediately
        # but still during transaction so it will be still atomic.
        def add_to_hash_ne(key, field, value, mapping_service = false)
          @driver.set_value_ne key, field, value
        end

        # Increment given field of the hash by a given number. If the field doesn't exist, it is created
        # and incremented.
        # mapping_service is special parameter MappingService during transactions. During transaction all
        # the commands are processed at the end, but mapping_service cannot wait and has to map name immediately
        # but still during transaction so it will be still atomic.
        def increment_hash(key, field, number, mapping_service = false)
          @driver.increment_field key, field, number
          get_hash_value(key, field)
        end

        # Delete certain fields from hash, returns number of deleted fields
        def delete_from_hash(key, hash_fields)
          hash_fields.each do |field|
            @driver.delete_value key, field
          end
        end

        def get_hash_value(key, field)
          #Return value or nil
          @driver.get_value key,field
        end

        def get_all_hash_values(key)
          #Returns array always
          @driver.get_values key
        end

        def get_all_hash_fields(key)
          #Returns array always
          @driver.get_fields key
        end

        #Determines if the given field exist in a hash located under the given key
        #Nontransactional = doesn't make sense to use this method in transaction
        def hash_value_exist?(key, field)
          @driver.field_exists? key, field
        end

        #Adds values from a given array to a list located in a database under the given key
        def add_to_list(key, values)
          values.each do |value|
            @driver.insert_value key, value # multiple values are not supported
            # although they should be (someone ought to be punished for that...)
          end
        end

        # Deletes all occurences of values specified in an array paraeter from a list under the given key.
        def delete_from_list(key, values)
          values.each do |val|
            @driver.remove_value key, val #deletes all occurences of val
          end
        end

        #Increments value under the given key in a database and returns that value
        def increment_string(key)
          @driver.increment_value key
          @driver.get_string key
        end

        #Decrements value under the given key in a database and returns that value
        def decrement_string(key)
          @driver.decrement_value key
          @driver.get_string key
        end

        # Renames key to a given new name
        # ====Parameters====
        # * +old_key+ - Old name of the key ro be renamed
        # * +new_key+ - New name of the key
        def rename_key(old_key, new_key)
          @driver.rename_key old_key, new_key
        end

        #Find all keys satisfying given pattern
        def find_keys(pattern = "*")
          @driver.find_keys pattern
        end

        #Saves multiple string values under the multiple keys specified in a hash parameter, example:
        #["key1" => "string1", "key2" => "string2"]
        #so basically the same function as save_string_entries with another type of parameter
        def save_hash_entries(key_value_hash, overwrite = true)
          key_value_list = []
          key_value_hash.each do |key, value|
            key_value_list << key
            key_value_list << value
          end
          if overwrite
            @driver.set_miltiple_strings(*key_value_list)
          else
            @driver.set_multiple_strings_ne(*key_value_list)
          end
        end

        #Saves multiple string values under the multiple keys specified in an array parameter, example:
        #["key1", "string1", "key2", "string2"]
        def save_string_entries(*key_string, overwrite)
          if(overwrite)
            @driver.set_multiple_strings(*key_string)
          else
            @driver.set_multiple_strings_ne(*key_string)
          end
        end

        #Deletes all values from database under the keys given as an array
        def delete_entries(keys)
          @driver.delete_keys keys
        end
        alias :delete_keys :delete_entries

        #Determines if there is any value under the given key in a database
        def entry_exist?(key)
          @driver.key_exists? key
        end

        #Returns all valus saved under the given key. Returned value can be hash, array or string.
        def find_value(key)
          type = @driver.get_type key
          return @driver.get_hash key if type == 'hash'
          if type == 'list'
            length = @driver.list_length key
            return @driver.list_range key, 0, length-1 if length > 0
            return nil
          end
          return @driver.get_string key if type == "string"
          # We don't use set or sorted set, so return nil
          nil
        end

        # Deletes all keys in all databases
        def delete_all_keys()
          @driver.flush_all
        end

        def commit
        end

        def transaction
          yield if block_given?
        end
        alias_method :pipelined, :transaction
      end
    end
  end
end
