class Storage
  def initialize(redis_url = ENV['REDISTOGO_URL'])
    @redis = get_client(redis_url)
  end

  def get(key)
    json = redis.get(key)
    return nil if json.nil?
    JSON.parse(json)
  end

  def del(key)
    redis.del(key)
  end

  def exists(key)
    redis.exists(key)
  end

  def keys(pattern)
    redis.keys(pattern)
  end

  def set(key, data, **args)
    redis.set(key, JSON.generate(data), args)
  end

  private

  attr_reader :redis

  def get_client(redis_url)
    Redis.new(url: redis_url)
  end
end
