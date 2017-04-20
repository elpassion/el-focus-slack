require_relative '../conversation'

class Workers::NotifySessionFinishedWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(bot_access_token, bot_conversation_channel)
    Conversation
      .create(bot_access_token, bot_conversation_channel)
      .post_message('session finished')
  end
end
