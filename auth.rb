require_relative 'config/initialize'

PERMISSION_SCOPE = 'bot+im:read+users:read+im:history+chat:write:user+dnd:write'

class Auth < Sinatra::Base
  add_to_slack_button = %(
    <a href=\"https://slack.com/oauth/authorize?scope=#{PERMISSION_SCOPE}&client_id=#{SLACK_CONFIG[:client_id]}&redirect_uri=#{SLACK_CONFIG[:redirect_uri]}\">
      <img alt=\"Add to Slack\" height=\"40\" width=\"139\" src=\"https://platform.slack-edge.com/img/add_to_slack.png\"/>
    </a>
  )

  get '/' do
    redirect '/begin_auth'
  end

  get '/begin_auth' do
    status 200
    body add_to_slack_button
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
      body 'Welcome to ElPomodoro Slack App :)'
    rescue Slack::Web::Api::Error => e
      status 403
      body "Auth failed! Reason: #{e.message}<br/>#{add_to_slack_button}"
    end
  end
end
