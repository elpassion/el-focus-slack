class Commands
  class UnknownMessage < Command
    def call
      respond_with "Sorry, I did not understand you. Available commands are: \n`start`\n`stop`\n`pause`\n`unpause` (you can also use `continue` and `resume`)\n`status` (shows minutes left)"
    end
  end
end
