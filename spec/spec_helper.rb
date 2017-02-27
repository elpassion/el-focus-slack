ENV['RACK_ENV'] ||= 'test'

Dotenv.load('.test.env') if defined?(Dotenv)

# It uses 'fakeredis'
require 'sidekiq/testing'

require 'webmock'

require_relative '../config/initialize'

RSpec.configure do |config|
  config.after(:each) do
    Redis.new.flushall
    Sidekiq::Worker.clear_all
  end
end
