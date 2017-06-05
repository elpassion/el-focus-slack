require_relative 'config/initialize'

class Auth < Sinatra::Base
  set :views, settings.root + '/views'

  get '/' do
    status 200
    erb :index
  end

  get '/stats' do
    stats = Sidekiq::Stats.new
    {
      failed: stats.failed,
      processed: stats.processed,
      scheduled_size: stats.scheduled_size,
    }.to_json
  end

  get '/support' do
    status 200
    erb :support
  end

  get '/finish_auth' do
    begin
      response = SlackClient.oauth(params['code'])

      user_id      = response['user_id']
      access_token = response['access_token']
      User.create(access_token: access_token, user_id: user_id)

      $storage.set "bot:#{response['team_id']}", {
        access_token: response['bot']['bot_access_token'],
        user_id: response['bot']['bot_user_id'] # don't know if needed
      }

      status 200
      erb :finish_auth
    rescue Slack::Web::Api::Error => e
      status 403
      erb :index, locals: { error: "Auth failed! Reason: #{e.message}" }
    end
  end
end
