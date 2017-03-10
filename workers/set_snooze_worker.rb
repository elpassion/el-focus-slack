class Workers::SetSnoozeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(user_id, time)
    user = User.new(user_id)
    return unless user.session_exists?

    client = SlackClient.for_acces_token(user.access_token)

    client.dnd_setSnooze(num_minutes: time)
  end
end
