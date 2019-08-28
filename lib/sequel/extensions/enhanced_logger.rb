# frozen-string-literal: true

require "sequel"

module EnhancedLogger
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
