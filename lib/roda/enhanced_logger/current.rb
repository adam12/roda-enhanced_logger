# frozen-string-literal: true

require "roda"

class Roda
  module EnhancedLogger
    ##
    # Data collection for request in current thread
    module Current
      extend self

      # Increment the accrued database time
      # @param value [Numeric]
      #   the value to increment
      # @return [Numeric]
      #   the updated value
      def increment_accrued_database_time(value)
        Thread.current[:accrued_database_time] ||= 0
        Thread.current[:accrued_database_time] += value
      end

      # The accrued database time
      # @return [Numeric]
      def accrued_database_time
        Thread.current[:accrued_database_time]
      end

      # Set accrued database time
      # @param value [Numeric]
      #   the value to set
      # @return [Numeric]
      #   the new value
      def accrued_database_time=(value)
        Thread.current[:accrued_database_time] = value
      end

      def increment_database_query_count(value = 1)
        Thread.current[:database_query_count] ||= 0
        Thread.current[:database_query_count] += value
      end

      def database_query_count
        Thread.current[:database_query_count]
      end

      def database_query_count=(value)
        Thread.current[:database_query_count] = value
      end

      # Reset the counters
      def reset
        self.accrued_database_time = nil
        self.database_query_count = nil
        true
      end
    end
  end
end
