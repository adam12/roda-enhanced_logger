# frozen-string-literal: true

require "sequel"

module EnhancedLogger
  UnsupportedSequelVersion = Class.new(StandardError)

  if ::Sequel::VERSION_NUMBER < 50240
    raise UnsupportedSequelVersion, "Sequel version must be 5.24 or greater"
  end

  module Sequel
    def skip_logging?
      false
    end

    def log_duration(duration, message)
      Thread.current[:accrued_database_time] ||= 0
      Thread.current[:accrued_database_time] += duration

      super
    end
  end

  ::Sequel::Database.register_extension :enhanced_logger, EnhancedLogger::Sequel
end
