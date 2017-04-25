class Commands
  class UserNotFoundMessage < Command
    def call
      respond_with "Looks like your access token has expired. Please go to #{host} and click \"Add to Slack\" button."
    end

    private

    def host
      ENV['SLACK_REDIRECT_URI'].gsub('/finish_auth', '')
    end
  end
end
