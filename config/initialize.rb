require 'rubygems'
require 'bundler/setup'

require_groups = [:default, :web, ENV['RACK_ENV']].compact
Bundler.require(*require_groups)

Dotenv.load if defined?(Dotenv)

# Load Slack app info into a hash called `config` from the environment variables assigned during setup
# See the "Running the app" section of the README for instructions.
SLACK_CONFIG = {
  client_id: ENV['SLACK_CLIENT_ID'],
  api_secret: ENV['SLACK_API_SECRET'],
  redirect_uri: ENV['SLACK_REDIRECT_URI'],
  verification_token: ENV['SLACK_VERIFICATION_TOKEN']
}
# Check to see if the required variables listed above were provided, and raise an exception if any are missing.
missing_params = SLACK_CONFIG.select { |key, value| value.nil? }
if missing_params.any?
  error_msg = missing_params.keys.join(", ").upcase
  raise "Missing Slack config variables: #{error_msg}"
end

require_relative './sidekiq_calculations'

Sidekiq.configure_client do |config|
  sidekiq_calculations = SidekiqCalculations.new
  sidekiq_calculations.raise_error_for_env!

  config.redis = {
    url: ENV['REDISTOGO_URL'],
    size: sidekiq_calculations.client_redis_size
  }
end

Sidekiq.configure_server do |config|
  sidekiq_calculations = SidekiqCalculations.new
  sidekiq_calculations.raise_error_for_env!

  puts "Starting sidekiq with concurrency: #{sidekiq_calculations.server_concurrency_size}"
  config.options[:concurrency] = sidekiq_calculations.server_concurrency_size
  config.redis = {
    url: ENV['REDISTOGO_URL']
  }
end

require_relative '../storage'
require_relative '../slack_client'
require_relative '../user'

$storage = Storage.new
