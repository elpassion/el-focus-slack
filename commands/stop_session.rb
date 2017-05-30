class Commands
  class StopSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Astop\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with('stopping session') { stop_session }
    end

    private

    def stop_session
      user.stop_session.ok do
        Workers::EndSnoozeWorker.perform_async(user.user_id)
        Workers::SetStatusWorker.perform_async(user.user_id, true)
      end
    end
  end

  register StopSession
end
