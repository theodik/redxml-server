require 'redis/dump'

module RedisDump
  def redis_load(filename)
    root_path = File.expand_path(File.dirname(__FILE__) + '/../fixtures')
    dump = ::Redis::Dump.new(0)
    data = File.open(File.join(root_path, filename), 'r').read
    dump.load data
  end

  def redis_clear
    ::Redis.new.flushall
  end
end

RSpec.configure do |config|
  config.include RedisDump
end
