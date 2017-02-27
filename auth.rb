require_relative 'config/initialize'

PERMISSION_SCOPE = 'bot+im:read+users:read+im:history+chat:write:user+dnd:write'

class Auth < Sinatra::Base
  set :views, settings.root + '/views'

  get '/' do
    status 200
    erb :index
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
