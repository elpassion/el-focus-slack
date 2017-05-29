ENV['RACK_ENV'] ||= 'test'

require 'dotenv'

Dotenv.load('.test.env')

# It uses 'fakeredis'
require 'sidekiq/testing'

require 'webmock'

require_relative '../config/initialize'

RSpec.configure do |config|
  storage = Storage.new

  config.before(:suite) do
    User.storage = storage
  end

  config.before(:each) do
    storage.clear
    Sidekiq::Worker.clear_all
  end
end
