module Session
  class TimeLeft
    def initialize(seconds)
      @seconds = seconds
    end

    attr_reader :seconds

    alias to_i seconds

    def minutes
      (seconds / 60.0).ceil
    end
  end
end
