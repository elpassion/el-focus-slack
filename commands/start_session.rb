class Commands
  class StartSession < Command
    def self.try_build(message, bot_conversation, user)
      match_data = /\Astart(\s(?<time>\d+))?\z/.match(message)
      return unless match_data

      new(bot_conversation, user, time: match_data['time'])
    end

    def call
      respond_with(message) { start_session }
    end

    private

    def start_session
      user.start_session(time).ok do
        Workers::RespondWithImBusyWorker.perform_async(user.user_id)
        Workers::SetSnoozeWorker.perform_async(user.user_id, (user.session_time_left / 60))
      end
    end

    def time
      params[:time]
    end

    def message
      "session started (#{time || User::DEFAULT_SESSION_TIME} minutes)"
    end
  end

  register StartSession
end
