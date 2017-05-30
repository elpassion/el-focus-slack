require_relative '../conversation'

class Workers::Scheduler
  include Sidekiq::Worker

  def perform(params)
    user_id                  = params.fetch('user_id')
    bot_access_token         = params.fetch('bot_access_token')
    bot_conversation_channel = params.fetch('bot_conversation_channel')

    user = User.new(user_id)
    user.decrement_send_busy_messages_jobs_count

    return if user.scheduled_send_busy_messages_jobs_count > 0

    unless user.session_exists?
      schedule_session_finish_notification(
        user_id,
        bot_access_token,
        bot_conversation_channel
      )
      schedule_clear_status(user_id)
      return
    end

    schedule_i_am_busy_workers(user) unless user.session_paused?

    self.class.perform_in 20, params
    user.increment_send_busy_messages_jobs_count
  end

  private

  def schedule_clear_status(user_id)
    Workers::SetStatusWorker.perform_async(user_id, true)
  end

  def schedule_session_finish_notification(user_id, bot_access_token, bot_conversation_channel)
    Workers::NotifySessionFinishedWorker.perform_async(user_id, bot_access_token, bot_conversation_channel)
  end

  def schedule_i_am_busy_workers(user)
    client = SlackClient.for_user(user)

    channels(client).each do |channel|
      Workers::SendImBusyMessageWorker.perform_async(
        user.user_id,
        channel.id,
        channel.user
      )
    end
  end

  def channels(client)
    actual_client = client.send(:client)  #TODO: do not use send(:client)
    actual_client.im_list.ims
  end
end
