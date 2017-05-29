class Workers::SetStatusWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  STATUS = {
    'status_text':  '',
    'status_emoji': ':tomato:'
  }

  def perform(user_id)
    user = User.new(user_id)
    return unless user.session_exists?

    client = SlackClient.for_user(user)

    client.users_profile_set(STATUS)
  end
end
