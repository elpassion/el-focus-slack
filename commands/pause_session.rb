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
        jobs = [
          { 'job_class' => Workers::EndSnoozeWorker.to_s, 'job_arguments' => [user.user_id] },
          { 'job_class' => Workers::SetStatusWorker.to_s, 'job_arguments' => [user.user_id, true] }
        ]
        Workers::OrderedMultipleJobsWorker.perform_async(jobs)
      end
    end
  end

  register PauseSession
end
