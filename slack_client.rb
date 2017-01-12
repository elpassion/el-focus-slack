require 'slack-ruby-client'

class SlackClient
  def initialize(team_id)
    @team_id = team_id
  end

  def get
    self.class.create_slack_client(bot_access_token)
  end

  private

  def bot_access_token
    $storage.get(team_id).fetch('bot_access_token')
  end

  def self.create_slack_client(slack_api_secret)
    Slack.configure do |config|
      config.token = slack_api_secret
      fail 'Missing API token' unless config.token
    end
    Slack::Web::Client.new
  end

  attr_reader :team_id
end