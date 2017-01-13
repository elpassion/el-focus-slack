class User
  def self.kv_storage
    @kv_storage ||= Storage.new
  end

  def initialize(user_id)
    @user_id = user_id
  end

  def busy?
    kv_storage.exists(busy_key)
  end

  private

  attr_reader :user_id

  def busy_key
    "busy:user:#{user_id}"
  end

  def user_key
    "user:#{user_id}"
  end

  def kv_storage
    self.class.kv_storage
  end
end

