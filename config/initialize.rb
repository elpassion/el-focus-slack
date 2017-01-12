require 'pp'

if File.exists?('.env')
  require 'dotenv'
  Dotenv.load
end
