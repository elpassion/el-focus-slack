class Storage
  def initialize(redis_url = ENV['REDISTOGO_URL'])
    @redis = get_client(redis_url)
  end

  def get(key)
    JSON.parse(redis.get(key))
  end

  # Returns
  # [{user_id => access_token}, {user_id => access_token}]
  def get_users
    user_keys = redis.keys('user:*')
    users_data = redis.mget(*user_keys).map do |json|
      JSON.parse(json)
    end
    user_keys = user_keys.map { |user_key| user_key.gsub('user:', '') }
    users_data = user_keys.zip(users_data)
    Hash[users_data]
  end

  def keys(pattern)
    redis.keys(pattern)
  end

  def set(key, data)
    redis.set(key, JSON.generate(data))
  end

  private

  attr_reader :redis

  def get_client(redis_url)
    Redis.new(url: redis_url)
  end
end
