class API < Sinatra::Base
  # configure do
  #   enable :logging
  #   file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  #   p file
  #   file.sync = true
  #   use Rack::CommonLogger, file
  # end

  # This is the endpoint Slack will post Event data to.
  post '/events' do
    request_data = JSON.parse(request.body.read)
    unless SLACK_CONFIG[:verification_token] == request_data['token']
      halt 403, "Invalid Slack verification token received: #{request_data['token']}"
    end

    if request.env['HTTP_X_SLACK_RETRY_NUM']
      halt 202, "Retries are ignored and this request is a retry (HTTP_X_SLACK_RETRY_NUM=#{request.env['HTTP_X_SLACK_RETRY_NUM']})"
    end

    puts "request_data['event']:"
    pp request_data['event']
    case request_data['type']
      # When you enter your Events webhook URL into your app's Event Subscription settings, Slack verifies the
      # URL's authenticity by sending a challenge token to your endpoint, expecting your app to echo it back.
      # More info: https://api.slack.com/events/url_verification
      when 'url_verification'
        request_data['challenge']

      when 'event_callback'
        response.headers['X-Slack-No-Retry'] = '1'  # It doesn't work, looks like Slack doesn't respect that
        team_id = request_data['team_id']
        event_data = request_data['event']

        case event_data['type']
          when 'message'
            Events.message(team_id, event_data)
          else
            puts "Unexpected event:\n"
            puts JSON.pretty_generate(request_data)
        end
        status 200 # Return HTTP status code 200 so Slack knows we've received the Event
    end
  end
end

class Events
  def self.message(team_id, event_data)
    user_id = event_data['user']
    return unless user_id # we don't react to messages sent by bot
    user = User.new(user_id)

    match_data = /\A(?<command>start|pause|unpause|stop)(\s(?<time>\d+))?\z/.match(event_data['text'])
    return unless match_data
    time_param = match_data['time']

    response = case match_data['command']
                 when 'start'   then start_pomodoro(time_param, user)
                 when 'pause'   then pause_pomodoro(user)
                 when 'stop'    then stop_pomodoro(user)
                 when 'unpause' then unpause_pomodoro(user)
               end

    bot_access_token = $storage.get("bot:#{team_id}").fetch('access_token')
    client(bot_access_token).chat_postMessage(text: response, channel: event_data['channel'])
  end

  private

  def self.message_or_error(result, message)
    return result.message if result.status == :error
    message
  end

  def self.unpause_pomodoro(user)
    message_or_error(user.unpause_session, 'session unpaused')
  end

  def self.stop_pomodoro(user)
    message_or_error(user.stop_session, 'session stopped')
  end

  def self.pause_pomodoro(user)
    message_or_error(user.pause_session, 'session paused')
  end

  def self.start_pomodoro(time_param, user)
    message_or_error(user.start_session(time_param), "session started (#{time_param || User::DEFAULT_SESSION_TIME} minutes)")
  end

  def self.client(access_token)
    SlackClient.new(access_token).get
  end

end
