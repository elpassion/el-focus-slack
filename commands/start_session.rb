class Commands
  class StartSession < Command
    def self.try_build(message, bot_conversation, user)
      match_data = /\Astart(\s(?<time>\d+))?\z/.match(message)
      return unless match_data

      new(bot_conversation, user, time: match_data['time'])
    end

    def call
      message = "session started (#{params[:time] || User::DEFAULT_SESSION_TIME} minutes)"
      respond_with message do
        user.start_session(params[:time])
      end
    end
  end

  register StartSession
end
