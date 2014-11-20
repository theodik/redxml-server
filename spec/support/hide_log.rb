require 'stringio'

module TestLogging
  extend self

  def create_logger
    @logger = Logger.new(output)
    @logger.formatter = RedXML::Server::Logging::Pretty.new
    RedXML::Server.logger = @logger
  end

  def output
    @output = StringIO.new
  end

  def read_output
    @output.string
  end

  def clear_output
    @output.string = ''
  end
end

# to-do: Make log output with failing message
RSpec.configure do |config|
  config.before(:suite) do
    TestLogging.create_logger
  end
  # Hide log messages until error happen
  config.after do |example|
    if example.exception
      $stderr.puts TestLogging.read_output
    end
    TestLogging.clear_output
  end
end
