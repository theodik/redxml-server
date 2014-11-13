require 'spec_helper'
require 'redxml/server/driver/redis'

RSpec.describe RedXML::Server::Driver::Redis do
  it_should_behave_like 'a driver'

  after(:each) do
    subject.flush_all
  end
end
