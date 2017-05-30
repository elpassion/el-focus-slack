class Commands
  class StopSession < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Astop\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with('Stopping session...') { stop_session }
    end

    private

    def stop_session
      user.stop_session.ok do
        jobs = [
          { 'job_class' => Workers::EndSnoozeWorker.to_s, 'job_arguments' => [user.user_id] },
          { 'job_class' => Workers::SetStatusWorker.to_s, 'job_arguments' => [user.user_id, true] }
        ]
        Workers::OrderedMultipleJobsWorker.perform_async(jobs)
      end
    end
  end

  register StopSession
end
