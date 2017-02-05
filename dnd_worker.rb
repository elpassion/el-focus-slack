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
        channel_user = channel.user

        puts "Downloading for [#{channel_id}]..."
        history = client.im_history(channel: channel_id, count: 1, unreads: 1)
        next if history.messages.empty?
        last_message = history.messages.last
        last_message_user = last_message.user
        # post_message if unread pending and last_message_user is_interlocutor?
        if history.unread_count_display > 0 && last_message_user == channel_user
          puts "sending message to channel #{channel_id}, user: #{last_message_user}"
          message = "Sorry, I'm busy right now. I'll be back in #{user.session_time_left / 60} minutes."
          client.chat_postMessage(channel: channel_id, text: message, as_user: true)
        end
      end

      puts 'scheduling next in 20 seconds'
      self.class.perform_in 20, user_id
    end

    private

    def ims(client)
      client.im_list.ims
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
