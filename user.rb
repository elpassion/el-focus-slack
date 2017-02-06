class User
  DEFAULT_SESSION_TIME = 25

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

  def start_session(time)
    if session_paused?
      return unpause_session
    end

    time ||= DEFAULT_SESSION_TIME
    time_left = time.to_i * 60
    storage.set session_key, { paused: 0, started_at: Time.now.to_i, time_left: time_left }, ex: time_left, nx: true
    Dnd::SendBusyMessagesWorker.perform_async(user_id)
    Dnd::SetSnoozeWorker.perform_async(user_id, time.to_i)
    SessionUpdateResult.ok
  end

  def stop_session
    storage.del session_key
    Dnd::EndSnoozeWorker.perform_async(user_id)
    SessionUpdateResult.ok
  end

  def pause_session
    unless session_exists?
      return SessionUpdateResult.error('no session')
    end

    if session_paused?
      return SessionUpdateResult.error('session already paused')
    end

    state = session.merge('paused' => 1, 'time_left' => session_time_left)

    storage.set session_key, state
    Dnd::EndSnoozeWorker.perform_async(user_id)
    SessionUpdateResult.ok
  end

  def session
    storage.get session_key
  end

  def session_exists?
    !!session
  end

  def session_paused?
    session_exists? && session.fetch('paused') == 1
  end

  def session_time_left
    started      = session.fetch('started_at').to_i
    elapsed_time = Time.now.to_i - started
    session.fetch('time_left').to_i - elapsed_time
  end

  def unpause_session
    current_state = session
    return SessionUpdateResult.error('no session') unless current_state
    return SessionUpdateResult.error('session not paused') if current_state.fetch('paused') == 0

    time_left = current_state.fetch('time_left').to_i
    state     = current_state.merge('started_at' => Time.now.to_i, 'paused' => 0)
    storage.set session_key, state, ex: time_left
    Dnd::SetSnoozeWorker.perform_async(user_id, (time_left / 60))
    SessionUpdateResult.ok
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

  class SessionUpdateResult
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
