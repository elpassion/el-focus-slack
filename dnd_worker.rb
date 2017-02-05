require_relative 'config/initialize'

module Dnd
  class SendBusyMessagesWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id)
      user = User.new(user_id)
      return unless user.session_exists?

      client = SlackClient.for_acces_token(user.access_token)

      ims(client).each do |channel|
        channel_id = channel.id
        interlocutor_id = channel.user
        SetBusyMessageToChannelWorker.perform_async(user_id, channel_id, interlocutor_id)
      end

      puts 'scheduling next in 20 seconds'
      self.class.perform_in 20, user_id
    end

    private

    def ims(client)
      client.im_list.ims
    end
  end

  class SetBusyMessageToChannelWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id, channel_id, interlocutor_id)
      user = User.new(user_id)
      client = SlackClient.for_acces_token(user.access_token)
      channel_history = client.im_history(channel: channel_id, count: 1, unreads: 1)
      return if channel_history.messages.empty?

      last_message_author_id = channel_history.messages.last.user
      unread_messages = channel_history.unread_count_display > 0
      if unread_messages && last_message_author_id == interlocutor_id
        puts "sending message to channel=#{channel_id}, interlocutor_id=#{interlocutor_id}"
        message = "Sorry, I'm busy right now. I'll be back in #{user.session_time_left / 60} minutes."
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
