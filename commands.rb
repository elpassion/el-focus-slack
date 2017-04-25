class Commands
  class << self
    def register(command)
      commands << command unless commands.include?(command)
    end

    def handle(message, conversation, user)
      return UserNotFoundMessage.new(conversation, user).call if !user.exists?

      handler = commands
                .lazy
                .map { |command| command.try_build(message, conversation, user) }
                .reject(&:nil?)
                .first || UnknownMessage.new(conversation, user)

      handler.call
    end

    private

    def commands
      @commands ||= []
    end
  end

  require_relative 'commands/command'
  require_relative 'commands/start_session'
  require_relative 'commands/pause_session'
  require_relative 'commands/unpause_session'
  require_relative 'commands/stop_session'
  require_relative 'commands/unknown_message'
  require_relative 'commands/user_not_found_message'
end
