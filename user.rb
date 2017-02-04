class User
  DEFAULT_POMODORO_TIME = 25

  def self.storage
    @storage ||= Storage.new
  end

  def initialize(user_id)
    @user_id = user_id
  end

  def access_token=(access_token)
    storage.set user_key, {
      access_token: access_token
    }
  end

  def access_token
    storage.get(user_key).fetch('access_token')
  end

  def start_pomodoro(time)
    time ||= DEFAULT_POMODORO_TIME
    time_left = time.to_i * 60
    storage.set session_key, { paused: 0, started_at: Time.now.to_i, time_left: time_left }, ex: time_left, nx: true
    Dnd::SendBusyMessageWorker.perform_async(user_id)
    Dnd::SetSnoozeWorker.perform_async(user_id, time.to_i)
    PomodoroSessionUpdateResult.ok
  end

  def stop_pomodoro
    storage.del session_key
    Dnd::EndSnoozeWorker.perform_async(user_id)
    PomodoroSessionUpdateResult.ok
  end

  def pause_pomodoro
    unless session_exists?
      return PomodoroSessionUpdateResult.error('no pomodoro session')
    end

    if session_paused?
      return PomodoroSessionUpdateResult.error('pomodoro session already paused')
    end

    session      = session()
    started      = session.fetch('started_at').to_i
    elapsed_time = Time.now.to_i - started
    time_left    = session.fetch('time_left').to_i - elapsed_time

    state = session.merge('paused' => 1, 'time_left' => time_left)

    storage.set session_key, state
    Dnd::EndSnoozeWorker.perform_async(user_id)
    PomodoroSessionUpdateResult.ok
  end

  def session_paused?
    session.fetch('paused') == 1
  end

  def session
    storage.get session_key
  end

  def session_exists?
    !!session
  end

  def unpause_pomodoro
    current_state = session
    return PomodoroSessionUpdateResult.error('no pomodoro session') unless current_state
    return PomodoroSessionUpdateResult.error('pomodoro session not paused') if current_state.fetch('paused') == 0

    time_left = current_state.fetch('time_left').to_i
    state     = current_state.merge('started_at' => Time.now.to_i, 'paused' => 0)
    storage.set session_key, state, ex: time_left
    Dnd::SetSnoozeWorker.perform_async(user_id, (time_left / 60))
    PomodoroSessionUpdateResult.ok
  end

  private

  attr_reader :user_id

  def session_key
    "user:session:#{user_id}"
  end

  def user_key
    "user:id:#{user_id}"
  end

  def storage
    self.class.storage
  end

  class PomodoroSessionUpdateResult
    attr_reader :status, :message

    def initialize(status, message = nil)
      @status = status # :ok, :error
      @message = message
    end

    def self.ok
      new(:ok)
    end

    def self.error(message = nil)
      new(:error, message)
    end
  end
end
