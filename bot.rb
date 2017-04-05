class API < Sinatra::Base
  require_relative 'events'
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
