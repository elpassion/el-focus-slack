require 'slack-ruby-client'

class SlackClient
  def initialize(access_token)
    @access_token = access_token
  end

  def get
    self.class.create_slack_client(access_token)
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

  def self.create_slack_client(slack_api_secret)
    Slack.configure do |config|
      config.token = slack_api_secret
      fail 'Missing API token' unless config.token
    end
    Slack::Web::Client.new
  end

  attr_reader :access_token
end