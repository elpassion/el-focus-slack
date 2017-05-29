class Workers::EndSnoozeWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  SNOOZE_ALREADY_NOT_ACTIVE_ERROR_MESSAGE = 'snooze_not_active'

  def perform(user_id)
    user = User.new(user_id)

    client = SlackClient.for_acces_token(user.access_token)

    client.dnd_endSnooze
  rescue Slack::Web::Api::Error => error
    return if error.message == SNOOZE_ALREADY_NOT_ACTIVE_ERROR_MESSAGE
    raise error
  end
end
