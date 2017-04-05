class Commands
  class PauseSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Apause\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with 'session paused' do
        user.pause_session
      end
    end
  end

  register PauseSession
end
