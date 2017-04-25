class Commands
  class UnknownMessage < Command
    def call
      respond_with "Sorry, I did not understand you.\nAvailable commands are `start`, `pause`, `unpause`, `stop`, `status`"
    end
  end
end
