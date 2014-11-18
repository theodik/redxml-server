require 'redis/dump'

module RedisDump
  def fixtures_path
    File.expand_path(File.dirname(__FILE__) + '/../fixtures')
  end

  def redis_load(filename)
    dump = ::Redis::Dump.new(0)
    data = File.open(File.join(fixtures_path, filename), 'r').read
    dump.load data
  end

  def redis_clear
    ::Redis.new.flushall
  end
end

RSpec.configure do |config|
  config.include RedisDump
end
