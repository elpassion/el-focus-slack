class Workers::RespondWithImBusyWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id)
    user = User.new(user_id)
    return unless user.session_exists?
    user.decrement_send_busy_messages_jobs_count
    if user.scheduled_send_busy_messages_jobs_count > 0
      puts "RETURNING:"
      puts "user.scheduled_send_busy_messages_jobs_count: #{user.scheduled_send_busy_messages_jobs_count}"
      return
    end

    unless user.session_paused?
      client = SlackClient.for_acces_token(user.access_token)

      channels = channels(client)
      channels.each do |channel|
        channel_id = channel.id
        interlocutor_id = channel.user
        SendImBusyMessageWorker.perform_async(user_id, channel_id, interlocutor_id)
      end
    end

    self.class.perform_in 20, user_id
    user.increment_send_busy_messages_jobs_count
  end

  private

  def channels(client)
    client.im_list.ims
  end
end
