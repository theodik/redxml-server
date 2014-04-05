require 'bundler/setup'
Bundler.setup

require 'redxml/server' # and any other gems you need

root_path = File.dirname(__FILE__)
Dir["#{root_path}/spec/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.expect_with :rspec do |c|
    # disable the `should` syntax
    c.syntax = :expect
  end
end
