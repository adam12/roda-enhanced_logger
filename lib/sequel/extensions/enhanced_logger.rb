# frozen-string-literal: true

require "sequel"

module EnhancedLogger
  module Sequel
    if ::Sequel::VERSION_NUMBER >= 50240
      def skip_logging?
        false
      end
    else
      def self.extended(base)
        return if base.loggers.any?

        require "logger"
        base.loggers = [Logger.new("/dev/null")]
      end
    end

    def log_duration(duration, _message)
      Roda::EnhancedLogger::Current.increment_accrued_database_time(duration)
      Roda::EnhancedLogger::Current.increment_database_query_count

      super
    end
  end

  ::Sequel::Database.register_extension :enhanced_logger, EnhancedLogger::Sequel
end
