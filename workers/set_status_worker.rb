class Workers::SetStatusWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  STATUS_JSON = '{"status_text":"","status_emoji":":tomato:"}'
  CLEAR_STATUS_JSON = '{"status_text":"","status_emoji":""}'

  def perform(user_id, clear = false)
    user = User.new(user_id)

    status = clear ? CLEAR_STATUS_JSON : STATUS_JSON

    client = SlackClient.for_user(user)

    client.call(:users_profile_set, profile: status)
  end
end
