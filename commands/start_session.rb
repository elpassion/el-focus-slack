class Commands
  class StartSession < Command
    def self.try_build(message, bot_conversation, user)
      return if user.session_paused?
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
        Workers::Scheduler.perform_async(
          user_id:                  user.user_id,
          bot_access_token:         bot_conversation.access_token,
          bot_conversation_channel: bot_conversation.channel
        )
        jobs = [
          { 'job_class' => Workers::SetSnoozeWorker.to_s, 'job_arguments' => [user.user_id, user.session_time_left.minutes] },
          { 'job_class' => Workers::SetStatusWorker.to_s, 'job_arguments' => [user.user_id] }
        ]
        Workers::OrderedMultipleJobsWorker.perform_async(jobs)
      end
    end

    def time
      params[:time]
    end

    def message
      "Session started! :tomato: (#{time || User::DEFAULT_SESSION_TIME} minutes)"
    end
  end

  register StartSession
end
