ENV['RACK_ENV'] ||= 'test'

Dotenv.load('.test.env') if defined?(Dotenv)

# It uses 'fakeredis'
require_relative '../config/initialize'
