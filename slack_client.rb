require 'slack-ruby-client'

class SlackClient
  attr_reader :access_token

  def initialize(access_token)
    @access_token = access_token
  end

  def call(method, *args)
    if args.empty?
      client.send(method)
    else
      client.send(method, *args)
    end
  rescue Slack::Web::Api::Error => error
    case error.message
      when 'missing_scope'
        host = ENV['SLACK_REDIRECT_URI'].gsub('/finish_auth', '')
        send_message_to_access_token_owner("Permission update required - please go to #{host} and click \"Add to Slack\" button to fully enjoy EL Focus!")
      when 'ratelimited'
        sleep rand(4) + 3
        call(method, *args)
      else
        raise error
    end
  end

  def send_message_to_access_token_owner(message)
    auth_test = client.send(:auth_test)
    team_id = auth_test.fetch('team_id')
    user_id = auth_test.fetch('user_id')
    bot_access_token = $storage.get("bot:#{team_id}").fetch('access_token')
    bot_client = self.class.create_slack_client(bot_access_token)
    bot_client.send(:chat_postMessage, channel: user_id, as_user: false, text: message)
  end

  def self.for_access_token(access_token)
    new(access_token)
  end

  def self.for_user(user)
    for_access_token(user.access_token)
  end

  def self.oauth(code)
    params = {
      client_id: SLACK_CONFIG[:client_id],
      client_secret: SLACK_CONFIG[:api_secret],
      redirect_uri: SLACK_CONFIG[:redirect_uri],
      code: code
    }
    Slack::Web::Client.new.oauth_access(params)
  end

  private

  def client
    @client ||=
      self.class.create_slack_client(access_token)
  end

  def self.create_slack_client(slack_api_secret)
    Slack.configure do |config|
      config.token = slack_api_secret
      fail 'Missing API token' unless config.token
    end
    Slack::Web::Client.new
  end
end
