require 'singleton'
require 'redxml/server/driver/base'

module RedXML
  module Server
    class Database
      class << self
        attr_reader :instance

        def connection
          estabilish_connection unless instance
          instance.connection
        end

        def estabilish_connection(options = RedXML::Server.options)
          @instance ||= new(options)
        end
      end

      def connection
        @connection ||= initialize_driver
      end

      private

      attr_reader :options

      def initialize(options)
        @options = options
        begin
          require("redxml/server/driver/#{driver_name}")
        rescue LoadError
          raise "Driver '#{driver_name}' is not supported"
          exit 1
        end
      end

      def initialize_driver
        name = options[:db][:driver].to_s.capitalize
        driver_klass = RedXML::Server::Driver.const_get(name)
        driver = driver_klass.new(options[:db])
        DatabaseInterface.new(driver)
      end

      def driver_name
        options[:db][:driver] or fail 'Database driver not specified'
      end

      def logger
        RedXML::Server.logger
      end
    end

    class DatabaseInterface
      # Represents a command sent into driver in pipelined or transaction mode to be able to
      # replay them later.
      Command = Struct.new(:method_name, :params)

      @@COMMAND_LIMIT = 10000
      def initialize(driver)
        @driver = driver
        #Array of commands for transactions and multi processing
        @commands = []

        #If we are in the middle of transaction or not
        @transaction = false
        #If we are using pipelining or not
        @pipelined = false
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
        if @transaction or @pipelined
          params = [key, hash, overwrite]
          @commands << Command.new(__method__, params)
          return
        else
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
      end

      # Add value to hash field if the field does not exist yet, returns true or false
      # mapping_service is special parameter MappingService during transactions. During transaction all
      # the commands are processed at the end, but mapping_service cannot wait and has to map name immediately
      # but still during transaction so it will be still atomic.
      def add_to_hash_ne(key, field, value, mapping_service = false)
        if  @transaction || @pipelined && !mapping_service
          params = [key, field, value]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.set_value_ne key, field, value
        end
      end

      # Increment given field of the hash by a given number. If the field doesn't exist, it is created
      # and incremented.
      # mapping_service is special parameter MappingService during transactions. During transaction all
      # the commands are processed at the end, but mapping_service cannot wait and has to map name immediately
      # but still during transaction so it will be still atomic.
      def increment_hash(key, field, number, mapping_service = false)
        if  @transaction or @pipelined and !mapping_service
          params = [key, field, number]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.increment_field key, field, number
          get_hash_value(key, field)
        end
      end

      # Delete certain fields from hash, returns number of deleted fields
      def delete_from_hash(key, hash_fields)
        if @transaction or @pipelined
          params = [key, hash_fields]
          @commands << Command.new(__method__, params)
          return
        else
          hash_fields.each do |field|
            @driver.delete_value key, field
          end
          #@driver.hdel key, *hash_fields
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
        if @transaction or @pipelined
          params = [key, values]
          @commands << Command.new(__method__, params)
          return
        else
          values.each do |value|
            @driver.insert_value key, value # multiple values are not supported
            # although they should be (someone ought to be punished for that...)
          end
        end
      end

      # Deletes all occurences of values specified in an array paraeter from a list under the given key.
      def delete_from_list(key, values)
        #LREM list -2 "hello" will remove the last two occurrences of "hello" in the list stored at list. =0 means all
        if @transaction or @pipelined
          params = [key, values]
          @commands << Command.new(__method__, params)
          return
        else
          values.each do |val|
            @driver.remove_value key, val #deletes all occurences of val
          end
        end
      end

      #Increments value under the given key in a database and returns that value
      def increment_string(key)
        if @transaction or @pipelined
          params = [key]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.increment_value key
          @driver.get_string key
        end
      end

      #Decrements value under the given key in a database and returns that value
      def decrement_string(key)
        if @transaction or @pipelined
          params = [key]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.decrement_value key
          @driver.get_string key
        end
      end

      # Renames key to a given new name
      # ====Parameters====
      # * +old_key+ - Old name of the key ro be renamed
      # * +new_key+ - New name of the key
      def rename_key(old_key, new_key)
        if @transaction or @pipelined
          params = [old_key, new_key]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.rename_key old_key, new_key
        end
      end

      #Find all keys satisfying given pattern
      def find_keys(pattern = "*")
        @driver.find_keys pattern
      end

      #Saves multiple string values under the multiple keys specified in a hash parameter, example:
      #["key1" => "string1", "key2" => "string2"]
      #so basically the same function as save_string_entries with another type of parameter
      def save_hash_entries(key_value_hash, overwrite = true)
        if @transaction or @pipelined
          params = [key_value_hash, overwrite]
          @commands << Command.new(__method__, params)
          return
        else
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
      end

      #Saves multiple string values under the multiple keys specified in an array parameter, example:
      #["key1", "string1", "key2", "string2"]
      def save_string_entries(*key_string, overwrite)
        if @transaction or @pipelined
          params = [key_string, overwrite]
          @commands << Command.new(__method__, params)
          return
        else
          if(overwrite)
            @driver.set_multiple_strings(*key_string)
          else
            @driver.set_multiple_strings_ne(*key_string)
          end
        end
      end

      #Deletes all values from database under the keys given as an array
      def delete_entries(keys)
        if @transaction or @pipelined
          params = [keys]
          @commands << Command.new(__method__, params)
          return
        else
          @driver.delete_keys keys
        end
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
        return nil
      end

      # Deletes all keys in all databases
      def delete_all_keys()
        @driver.flush_all
      end

      def check_buffer
        if @commands > @@COMMAND_LIMIT
          logger.warn "db_interface: buffer full"
          commit
        end
      end

      def commit
        @driver.transaction do
          @transaction = false
          @pipelined = false
          @commands.each do |command|
            send command.method_name, *command.params
          end
          @commands.clear
        end
      end

      # Method is used to mark transaction processing, all methods inside transactions are saved as Command
      # and commited at the end.
      # Note: Transaction are currently not fully operational, there is an exception in MappingService, current
      # code needs MappingService to be able to write to database immediately even during transactions = those
      # writes are not transactional even during trasaction!
      # Note 2: Transactions are only half-complete, it is obvious that it's impossible to use this transation when
      # you need return values (write t database, get value, write to database based on returned value). Also
      # Redis has no support for rollback, so if Redis crashes in the middle of transation, it ispossible that it
      # stays in an unstable state (shalf of keys written, rest none)
      def transaction
        @transaction = true
        yield
        commit
      end

      def pipelined
        @pipelined = true
        yield
        commit
      end
    end
  end
end
