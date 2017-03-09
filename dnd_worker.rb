require_relative 'config/initialize'

module Dnd
  class RespondWithImBusyWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id)
      user = User.new(user_id)
      return unless user.session_exists?
      user.decrement_send_busy_messages_jobs_count
      if user.scheduled_send_busy_messages_jobs_count > 0
        return
      end

      unless user.session_paused?
        client = SlackClient.for_acces_token(user.access_token)

        channels = channels(client)
        puts "channels: #{channels}"
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

  class SendImBusyMessageWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id, channel_id, interlocutor_id)
      user = User.new(user_id)
      client = SlackClient.for_acces_token(user.access_token)
      channel_history = client.im_history(channel: channel_id, count: 1, unreads: 1)
      return if channel_history.messages.empty?

      last_message_author_id = channel_history.messages.last.user
      unread_messages = channel_history.unread_count_display > 0
      if unread_messages && last_message_author_id == interlocutor_id && interlocutor_id != 'USLACKBOT'
        puts "sending message to channel=#{channel_id}, interlocutor_id=#{interlocutor_id}"
        time_left = user.session_time_left / 60
        minutes_text = time_left > 1 ? 'minutes' : 'minute'
        message = "Sorry, I'm busy right now. I'll be back in #{time_left} #{minutes_text}. _sent by El Pomodoro Slack App_"
        client.chat_postMessage(channel: channel_id, text: message, as_user: true)
      end
    end
  end

  class SetSnoozeWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id, time)
      user = User.new(user_id)
      return unless user.session_exists?

      client = SlackClient.for_acces_token(user.access_token)

      client.dnd_setSnooze(num_minutes: time)
    end
  end

  class EndSnoozeWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id)
      user = User.new(user_id)

      client = SlackClient.for_acces_token(user.access_token)

      client.dnd_endSnooze
    end

  end

end
