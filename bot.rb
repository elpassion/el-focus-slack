class API < Sinatra::Base
  # This is the endpoint Slack will post Event data to.
  post '/events' do
    # Extract the Event payload from the request and parse the JSON
    request_data = JSON.parse(request.body.read)
    # Check the verification token provided with the request to make sure it matches the verification token in
    # your app's setting to confirm that the request came from Slack.
    unless SLACK_CONFIG[:verification_token] == request_data['token']
      halt 403, "Invalid Slack verification token received: #{request_data['token']}"
    end

    case request_data['type']
      # When you enter your Events webhook URL into your app's Event Subscription settings, Slack verifies the
      # URL's authenticity by sending a challenge token to your endpoint, expecting your app to echo it back.
      # More info: https://api.slack.com/events/url_verification
      when 'url_verification'
        request_data['challenge']

      when 'event_callback'
        # Get the Team ID and Event data from the request object
        team_id = request_data['team_id']
        event_data = request_data['event']

        # Events have a "type" attribute included in their payload, allowing you to handle different
        # Event payloads as needed.
        case event_data['type']
          when 'message'
            # Event handler for messages, including Share Message actions
            Events.message(team_id, event_data)
          else
            # In the event we receive an event we didn't expect, we'll log it and move on.
            puts "Unexpected event:\n"
            puts JSON.pretty_generate(request_data)
        end
        # Return HTTP status code 200 so Slack knows we've received the Event
        status 200
    end
  end
end

class Events
  require_relative './dnd_worker'

  def self.message(team_id, event_data)
    user_id = event_data['user']
    return unless user_id # we don't react to messages sent by bot
    user = User.new(user_id)

    match_data = /\Apomodoro (?<command>start|pause|unpause|stop)(\s(?<time>\d+))?\z/.match(event_data['text'])
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
    message_or_error(user.unpause_pomodoro, 'pomodoro session unpaused')
  end

  def self.stop_pomodoro(user)
    message_or_error(user.stop_pomodoro, 'pomodoro session stopped')
  end

  def self.pause_pomodoro(user)
    message_or_error(user.pause_pomodoro, 'pomodoro session paused')
  end

  def self.start_pomodoro(time_param, user)
    message_or_error(user.start_pomodoro(time_param), 'pomodoro session started')
  end

  def self.client(access_token)
    SlackClient.new(access_token).get
  end

end
