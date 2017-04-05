class Commands
  class UnpauseSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Aunpause\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with 'session unpaused' do
        user.unpause_session
      end
    end
  end

  register UnpauseSession
end
