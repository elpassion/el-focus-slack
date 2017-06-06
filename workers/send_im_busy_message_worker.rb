class Workers::SendImBusyMessageWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id, channel_id, interlocutor_id)
    user = User.new(user_id)
    client = SlackClient.for_user(user)
    channel_history = client.call(:im_history, channel: channel_id, count: 1, unreads: 1)
    return if channel_history.messages.empty?

    last_message_author_id = channel_history.messages.last.user
    unread_messages = channel_history.unread_count_display > 0
    if unread_messages && last_message_author_id == interlocutor_id && interlocutor_id != 'USLACKBOT'
      puts "sending message to channel=#{channel_id}, interlocutor_id=#{interlocutor_id}"
      time_left = user.session_time_left.minutes
      minutes_text = time_left > 1 ? 'minutes' : 'minute'
      message = "Sorry, I'm busy right now. I'll be back in #{time_left} #{minutes_text}. _sent by EL Focus_"
      client.call(:chat_postMessage, channel: channel_id, text: message, as_user: true)
    end
  end
end
