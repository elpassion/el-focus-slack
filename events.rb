class Events
  require_relative 'slack_client'
  require_relative 'conversation'
  require_relative 'commands'

  class << self
    def message(team_id, event_data)
      return unless event_data['user']

      message      = event_data['text']
      user         = User.new(event_data['user'])
      conversation = Conversation.create(
        $storage.get("bot:#{team_id}").fetch('access_token'),
        event_data['channel']
      )

      Commands.handle(message, conversation, user)
    end

    private

    def client(access_token)
      SlackClient.for_acces_token(access_token)
    end
  end
end
