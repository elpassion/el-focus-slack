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
  # You may notice that user and channel IDs may be found in
  # different places depending on the type of event we're receiving.

  def self.message(*args)
    $storage.get_users.each do |user_id, user_data|
      client = client(user_data.fetch('access_token'))
      ims = client.im_list.ims
      ims.each do |channel|
        puts "Downloading for [#{channel.id}]..."
        history = client.im_history(channel: channel.id, count: 1, unreads: 1)
        return if history.messages.empty?
        last_message = history.messages.last
        last_message_user = last_message.user
        if history.unread_count_display > 0
          pp history
          # post_message if last_message_user is_interlocutor?
        end
      end
    end
  end

  private

  def self.client(access_token)
    SlackClient.new(access_token).get
  end

end
