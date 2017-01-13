require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require_relative 'config/initialize'
require_relative 'dnd_worker'

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['REDISTOGO_URL'] }
end

class SidekiqServer < Sinatra::Base
end
