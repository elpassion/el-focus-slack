require 'pp'
require_relative '../storage'
require_relative '../slack_client'

if File.exists?('.env')
  require 'dotenv'
  Dotenv.load
end

$storage = Storage.new
