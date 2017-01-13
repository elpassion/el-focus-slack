require 'rubygems'
require 'bundler/setup'

require_groups = [:default, :web, ENV['RACK_ENV']].compact
Bundler.require(*require_groups)
Dotenv.load if defined?(Dotenv)

require 'pp'
require 'json'

require './storage'
require './slack_client'
require './config/initialize'
require './auth'
require './bot'

# Initialize the app and create the API (bot) and Auth objects.
run Rack::Cascade.new [API, Auth]
