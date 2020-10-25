# frozen-string-literal: true

require "roda"

class Roda
  module EnhancedLogger
    module Current
      extend self

      def increment_accrued_database_time(value)
        Thread.current[:accrued_database_time] ||= 0
        Thread.current[:accrued_database_time] += value
      end

      def accrued_database_time
        Thread.current[:accrued_database_time]
      end

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

      def reset
        self.accrued_database_time = nil
        self.database_query_count = nil
      end
    end
  end
end
