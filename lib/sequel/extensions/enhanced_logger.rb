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

    def log_duration(duration, message)
      Thread.current[:accrued_database_time] ||= 0
      Thread.current[:accrued_database_time] += duration

      Thread.current[:database_query_count] ||= 0
      Thread.current[:database_query_count] += 1

      super
    end
  end

  ::Sequel::Database.register_extension :enhanced_logger, EnhancedLogger::Sequel
end
