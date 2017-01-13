require_relative 'config/initialize'

class Dnd
  class ImList < Dnd
    def run!
      storage.get_users.each do |user_id, user_data|
        access_token = user_data.fetch('access_token')
        client = client(access_token)
        ims = client.im_list.ims
        ims.each do |channel|
          SendBusyMessageWorker.perform_async(channel.id, access_token, channel.user)
        end
      end
    end
  end

  class SendBusyMessageWorker < Dnd
    include Sidekiq::Worker

    def perform(channel_id, access_token, channel_user)
      client = client(access_token)
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

    private

    def client(access_token)
      SlackClient.new(access_token).get
    end
  end

  private

  def client(access_token)
    SlackClient.new(access_token).get
  end

  def storage
    @storage ||= Storage.new
  end
end
