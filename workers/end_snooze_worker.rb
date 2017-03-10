class Workers::EndSnoozeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id)
    user = User.new(user_id)

    client = SlackClient.for_acces_token(user.access_token)

    client.dnd_endSnooze
  end
end
