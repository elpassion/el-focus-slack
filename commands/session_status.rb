class Commands
  class SessionStatus < Command
    def self.try_build(message, bot_conversation, user)
      return unless /\Astatus\z/ =~ message

      new(bot_conversation, user)
    end

    def call
      respond_with status
    end

    private

    def status
      status = user.session_status
      case status
      when User::NoSession         then 'No session in progress'
      when User::SessionPaused     then 'Session paused'
      when User::SessionInProgress then format_time_left(status.time_left)
      end
    end

    def format_time_left(seconds_left)
      minutes = (seconds_left / 60.0).round
      "#{minutes} #{minutes > 1 ? 'minutes' : 'minute'} left in session"
    end
  end

  register SessionStatus
end
