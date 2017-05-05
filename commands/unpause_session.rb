class Commands
  class UnpauseSession < Command
    def self.try_build(message, bot_conversation, user)
      matcher = if user.session_paused?
                  /\Aunpause|start\z/
                else
                  /\Aunpause\z/
                end
      return unless matcher =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with('session unpaused') { unpause_session }
    end

    private

    def unpause_session
      user.unpause_session.ok do
        Workers::SetSnoozeWorker.perform_async(user.user_id, user.session_time_left.minutes)
      end
    end
  end

  register UnpauseSession
end
