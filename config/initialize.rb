require 'pp'
require_relative '../storage'

if File.exists?('.env')
  require 'dotenv'
  Dotenv.load
end

$storage = Storage.new
