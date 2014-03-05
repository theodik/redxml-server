class RedXML::Driver::Base
  ## Keys

  # Returns all keys
  def get_keys
    raise NotImplementedError
  end

  # Returns string representation of the type of the value at key
  def get_type(key)
    raise NotImplementedError
  end

  # Renames key to new_key
  def rename_key(key, new_key)
    raise NotImplementedError
  end

  # Returns true if a key exists
  def key_exists?(key)
    raise NotImplementedError
  end

  def delete_key(key)
    raise NotImplementedError
  end

  ## Strings

  # Set the string value of a key
  #
  # If key already holds a value, it is overwritten.
  def set_string(key, value)
    raise NotImplementedError
  end

  # Get the value of a key
  def get_string(key)
    raise NotImplementedError
  end

  # Append value to a key
  #
  # If key doesnt exist, it is created first and then set to value.
  def append_string(key, value)
    raise NotImplementedError
  end

  # Increment value stored at key by value
  #
  # If key doesnt exists, it is set to 0 and incremented.
  def increment_value(key, value = 1)
    raise NotImplementedError
  end

  # Decrement value stored at key by value
  #
  # If key doesnt exists, it is set to 0 and decremented.
  def decrement_value(key, value = 1)
    raise NotImplementedError
  end

  # Hashes

  #
  def set_hash(key, hash)
    raise NotImplementedError
  end

  def get_hash(key)
    raise NotImplementedError
  end

  def set_value(key, field, value)
    raise NotImplementedError
  end

  def increment_field(key, field, value = 1)
    raise NotImplementedError
  end

  def decrement_field(key, field, value = 1)
    raise NotImplementedError
  end

  def get_value(key, field)
    raise NotImplementedError
  end

  def get_values(key)
    raise NotImplementedError
  end

  def get_fields(key)
    raise NotImplementedError
  end

  def field_exists?(key, field)
    raise NotImplementedError
  end

  def delete_value(key, field)
    raise NotImplementedError
  end

  # Lists
  # TODO: Is it needed?

  # Sets
  # TODO: Is it needed?
end
