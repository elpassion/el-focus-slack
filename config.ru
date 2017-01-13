require 'pp'
require 'json'

require './auth.rb'
require './bot.rb'

# Initialize the app and create the API (bot) and Auth objects.
run Rack::Cascade.new [API, Auth]
