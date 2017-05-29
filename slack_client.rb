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
