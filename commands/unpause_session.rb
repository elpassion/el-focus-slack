class Commands
  class UnpauseSession < Command
    def self.try_build(message, bot_conversation, user)
      matcher = if user.session_paused?
                  /\Aunpause|start|continue|resume\z/
                else
                  /\Aunpause\z/
                end
      return unless matcher =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with('Session unpaused! :tomato:') { unpause_session }
    end

    private

    def unpause_session
      user.unpause_session.ok do
        jobs = [
          { 'job_class' => Workers::SetSnoozeWorker.to_s, 'job_arguments' => [user.user_id, user.session_time_left.minutes] },
          { 'job_class' => Workers::SetStatusWorker.to_s, 'job_arguments' => [user.user_id] }
        ]
        Workers::OrderedMultipleJobsWorker.perform_async(jobs)
      end
    end
  end

  register UnpauseSession
end
