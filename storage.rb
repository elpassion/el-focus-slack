class Storage
  def initialize(redis_url = ENV['REDISTOGO_URL'])
    @redis = get_client(redis_url)
  end

  def get(key)
    JSON.parse(redis.get(key))
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
