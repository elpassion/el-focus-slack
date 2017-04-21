class User
  require_relative 'workers'

  DEFAULT_SESSION_TIME = 25

  attr_reader :user_id

  def self.create(access_token:, user_id:)
    user = new(user_id)
    user.access_token = access_token
    user
  end

  def self.storage
    if @storage
      puts "Connection already exists, no need to create new one."
      @storage
    else
      puts "Initializing new connection."
      puts "Should we? Maybe we can use global connection? #{!!$storage}"
      Storage.new
    end
  end

  def self.storage=(storage)
    @storage = storage
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

  def decrement_send_busy_messages_jobs_count
    storage.set(send_busy_messages_jobs_count_key, scheduled_send_busy_messages_jobs_count - 1)
  end

  def increment_send_busy_messages_jobs_count
    storage.set(send_busy_messages_jobs_count_key, scheduled_send_busy_messages_jobs_count + 1)
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
    SessionUpdateResult.ok
  end

  def scheduled_send_busy_messages_jobs_count
    count = storage.get(send_busy_messages_jobs_count_key)
    if count
      return count.to_i
    else
      0
    end
  end

  def start_session(time = nil)
    if session_in_progress?
      return SessionUpdateResult.error("Session already in progress (time left: #{session_time_left / 60} minutes)")
    end

    if session_paused?
      return unpause_session
    end

    time ||= DEFAULT_SESSION_TIME
    time_left = time.to_i * 60
    storage.set session_key, { paused: 0, started_at: Time.now.to_i, time_left: time_left }, ex: time_left, nx: true
    increment_send_busy_messages_jobs_count
    SessionUpdateResult.ok
  end

  def stop_session
    return SessionUpdateResult.error('No session in progress') unless session_exists?
    storage.del session_key
    storage.del send_busy_messages_jobs_count_key
    SessionUpdateResult.ok
  end

  def send_busy_messages_jobs_count_key
    "user:busy_messages_jobs_count:#{user_id}"
  end

  def session
    storage.get session_key
  end

  def session_exists?
    !!session
  end

  def session_in_progress?
    session_exists? && session.fetch('paused') == 0
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
    return SessionUpdateResult.error('No session in progress') unless current_state
    return SessionUpdateResult.error('No paused session') if current_state.fetch('paused') == 0

    time_left = current_state.fetch('time_left').to_i
    state     = current_state.merge('started_at' => Time.now.to_i, 'paused' => 0)
    storage.set session_key, state, ex: time_left
    SessionUpdateResult.ok
  end

  private

  def session_key
    "user:session:#{user_id}"
  end

  def user_key
    "user:#{user_id}"
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

    def ok?
      status == :ok
    end

    def ok
      yield if block_given? && ok?
      self
    end

    def self.ok
      new(:ok)
    end

    def self.error(message = nil)
      new(:error, message)
    end
  end
end
