require 'sinatra/base'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require_relative 'config/initialize'

class SidekiqServer < Sinatra::Base
end
