class Commands
  class Command
    def initialize(bot_conversation, user, **params)
      @bot_conversation = bot_conversation
      @user             = user
      @params           = params
    end

    def call
      raise NotImplementedError
    end

    private

    attr_reader :bot_conversation, :user, :params

    def respond_with(message)
      result = if block_given?
                 yield
               end

      bot_conversation.post_message message_or_error(result, message)
    end

    def message_or_error(result, message)
      return result.message if result && result.status == :error
      message
    end
  end
end
