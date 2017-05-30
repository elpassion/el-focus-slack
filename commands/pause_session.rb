class Commands
  class PauseSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Apause\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with('session paused') { pause_session }
    end

    private

    def pause_session
      user.pause_session.ok do
        Workers::EndSnoozeWorker.perform_async(user.user_id)
        Workers::SetStatusWorker.perform_async(user.user_id, true)
      end
    end
  end

  register PauseSession
end
