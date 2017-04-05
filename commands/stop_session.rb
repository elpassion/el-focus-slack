class Commands
  class StopSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Astop\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with 'session stopped' do
        user.stop_session
      end
    end
  end

  register StopSession
end
