class Conversation
  require_relative 'slack_client'

  def self.create(access_token, channel)
    new(SlackClient.for_acces_token(access_token), channel)
  end

  def initialize(client, channel)
    @client  = client
    @channel = channel
  end

  def post_message(message)
    client.chat_postMessage(text: message, channel: channel)
  end

  private

  attr_reader :client, :channel
end
