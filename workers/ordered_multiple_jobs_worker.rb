# From Slack doc (https://api.slack.com/docs/rate-limits):
# In general we allow applications that integrate with Slack to send no more than one message per second.
# If you need schedule multiple calls to Slack API, use this class to prevent Slack::Web::Api::Error: ratelimited error.
# This Worker performs multiple jobs one after another.
class Workers::OrderedMultipleJobsWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(jobs_collection)
    jobs_collection.each do |hash|
      job_class = hash.fetch('job_class')
      job_arguments = hash.fetch('job_arguments')
      Kernel.const_get(job_class).new.perform(*job_arguments)
      sleep 1
    end
  end

end
