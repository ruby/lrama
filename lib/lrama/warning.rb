module Lrama
  class Warning
    attr_reader :errors, :warns

    def initialize
      @errors = []
      @warns = []
    end

    def error(message)
      @errors << message
    end

    def warn(message)
      @warns << message
    end

    def has_error?
      !@errors.empty?
    end
  end
end
