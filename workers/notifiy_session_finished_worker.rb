require_relative '../conversation'

class Workers::NotifySessionFinishedWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id, bot_access_token, bot_conversation_channel)
    turn_off_snooze(user_id)
    send_message_about_finished_session(bot_access_token, bot_conversation_channel)
  end

  private

  def send_message_about_finished_session(bot_access_token, bot_conversation_channel)
    Conversation
      .create(bot_access_token, bot_conversation_channel)
      .post_message('session finished')
  end

  def turn_off_snooze(user_id)
    Workers::EndSnoozeWorker.new.perform(user_id)
  end
end
