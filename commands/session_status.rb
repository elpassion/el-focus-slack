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
      when User::NoSession         then 'No session in progress :coffee:'
      when User::SessionPaused     then 'Session paused :stopwatch:'
      when User::SessionInProgress then format_time_left(status.time_left)
      end
    end

    def format_time_left(time_left)
      minutes = time_left.minutes
      "#{minutes} #{minutes > 1 ? 'minutes' : 'minute'} left in session :timer_clock:"
    end
  end

  register SessionStatus
end
