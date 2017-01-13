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

# This class contains all of the Event handling logic.
class Events
  require_relative './dnd_worker'
  # You may notice that user and channel IDs may be found in
  # different places depending on the type of event we're receiving.

  def self.message(team_id, event_data)
    user_id = event_data['user']
    return unless user_id # we don't react to messages sent by bot

    match_data = /\Apomodoro (?<command>start|pause|unpause|stop)(\s(?<time>\d+))?\z/.match(event_data['text'])
    return unless match_data

    response = case match_data['command']
                 when 'start'   then start_pomodoro(user_id, match_data['time'])
                 when 'pause'   then pause_pomodoro(user_id)
                 when 'stop'    then stop_pomodoro(user_id)
                 when 'unpause' then unpause_pomodoro(user_id)
               end

    bot_access_token = $storage.get("bot:#{team_id}").fetch('access_token')
    client(bot_access_token).chat_postMessage(text: response, channel: event_data['channel'])
  end

  private

  def self.client(access_token)
    SlackClient.new(access_token).get
  end

  def self.start_pomodoro(user_id, time)
    time ||= 25
    time_left = time.to_i * 60
    $storage.set "busy:user:#{user_id}", { paused: 0, started_at: Time.now.to_i, time_left: time_left }, ex: time_left, nx: true
    Dnd::SendBusyMessageWorker.perform_async(user_id)
    'started pomodoro session'
  end

  def self.stop_pomodoro(user_id)
    $storage.del "busy:user:#{user_id}"
    'finished pomodoro session'
  end

  def self.pause_pomodoro(user_id)
    current_state = $storage.get "busy:user:#{user_id}"
    return 'no pomodoro session' unless current_state
    return 'pomodoro session already paused' if current_state.fetch('paused') == 1

    started   = current_state.fetch('started_at').to_i
    elapsed_time = Time.now.to_i - started
    time_left = current_state.fetch('time_left').to_i - elapsed_time

    state = current_state.merge('paused' => 1, 'time_left' => time_left)

    $storage.set "busy:user:#{user_id}", state
    'paused pomodoro session'
  end

  def self.unpause_pomodoro(user_id)
    current_state = $storage.get "busy:user:#{user_id}"
    return 'no pomodoro session' unless current_state
    return 'pomodoro session not paused' if current_state.fetch('paused') == 0

    time_left = current_state.fetch('time_left').to_i
    state     = current_state.merge('started_at' => Time.now.to_i, 'paused' => 0)
    pp $storage.set "busy:user:#{user_id}", state, ex: time_left
    'pomodoro unpaused'
  end

end
