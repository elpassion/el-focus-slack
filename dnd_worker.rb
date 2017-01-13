require_relative 'config/initialize'

module Dnd
  class SendBusyMessageWorker
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(user_id)
      user = User.new(user_id)
      return unless user.busy?
      access_token = storage.get("user:#{user_id}").fetch('access_token')

      client = client(access_token)

      ims(client).each do |channel|
        channel_id = channel.id
        channel_user = channel.user

        puts "Downloading for [#{channel_id}]..."
        history = client.im_history(channel: channel_id, count: 1, unreads: 1)
        return if history.messages.empty?
        last_message = history.messages.last
        last_message_user = last_message.user
        # post_message if unread pending and last_message_user is_interlocutor?
        if history.unread_count_display > 0 && last_message_user == channel_user
          puts "sending message to channel #{channel_id}, user: #{last_message_user}"
          client.chat_postMessage(channel: channel_id, text: 'This is ElPomodoro Slack App test!', as_user: true)
        end
      end

      puts 'scheduling next in 20 seconds'
      self.class.perform_in 20, user_id
    end


    private

    def client(access_token)
      SlackClient.new(access_token).get
    end

    def ims(client)
      client.im_list.ims
    end

    def busy?(user_id)
      $storage.exists("busy:#{user_id}")
    end

    def storage
      $storage
    end

  end
end
