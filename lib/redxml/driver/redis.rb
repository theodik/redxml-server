class RedXML::Driver::Redis
  def initialize(options={})
    begin
      require 'redis'
    rescue LoadError => e
      raise LoadError, "RedXML's redis driver is unable to load `redis`, please install the gem and add `gem 'redis'` to your Gemfile if you are using bundler."
    end

    setup_options!(options)
    @redis = Redis.new(options)
  end

  ## Keys

  # Returns all keys
  def get_keys
    @redis.keys '*'
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

  def delete_key(key)
    @redis.del key
  end


  ## Strings
  @redis.append key, value
  # Set the string value of a key
  #
  # If key already holds a value, it is overwritten.
  def set_string(key, value)
    @redis.set key, value
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

  # Hashes

  #
  def set_hash(key, hash)
    @redis.hmset key, *hash.flatten
  end

  def get_hash(key)
    @redis.hgetall key
  end

  def set_value(key, field, value)
    @redis.hset key, field, value
  end

  def increment_field(key, field, value = 1)
    @redis.hincrby key, field, value
  end

  def decrement_field(key, field, value = 1)
    @redis.hincrby key, field, -value
  end

  def get_value(key, field)
    @redis.hget key, field
  end

  def get_values(key)
    @redis.hvals key
  end

  def get_fields(key)
    @redis.hkeys key
  end

  def field_exists?(key, field)
    @redis.hexists key, field
  end

  def delete_value(key, field)
    @redis.hdel key, field
  end

  # Lists
  # TODO: Is it needed?

  # Sets
  # TODO: Is it needed?

  private
  def setup_options!(options)
    options
  end
end
