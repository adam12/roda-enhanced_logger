# frozen-string-literal: true

require "roda"

class Roda
  module EnhancedLogger
    class Instance
      attr_reader :root
      attr_reader :log_entries
      attr_reader :logger
      attr_reader :matches
      attr_reader :timer
      attr_reader :filter

      def initialize(logger, env, instance_id, root, filter)
        @logger = logger
        @root = root
        @log_entries = []
        @matches = []
        @timer = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @filter = filter || proc { false }
        if env["enhanced_logger_id"].nil?
          @primary = true
          env["enhanced_logger_id"] = instance_id
        else
          @primary = false
        end
      end

      def add_match(caller)
        @matches << caller
      end

      def add_log_entry(record)
        @log_entries << record
      end

      def add(status, request, trace = false)
        if (last_matched_caller = matches.last)
          handler = format("%s:%d",
            Pathname(last_matched_caller.path).relative_path_from(root),
            last_matched_caller.lineno)
        end

        meth =
          case status
          when 400..499
            :warn
          when 500..599
            :error
          else
            :info
          end

        data = {
          duration: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - timer).round(4),
          status: status,
          verb: request.request_method,
          path: request.path,
          remaining_path: request.remaining_path,
          handler: handler,
          params: request.params
        }

        if (db = Roda::EnhancedLogger::Current.accrued_database_time)
          data[:db] = db.round(6)
        end

        if (query_count = Roda::EnhancedLogger::Current.database_query_count)
          data[:db_queries] = query_count
        end

        if trace
          matches.each do |match|
            add_log_entry([meth, format("  %s (%s:%s)",
              File.readlines(match.path)[match.lineno - 1].strip.sub(" do", ""),
              Pathname(match.path).relative_path_from(root),
              match.lineno)])
          end
        end

        return if filter.call(request.path)

        add_log_entry([meth, "#{request.request_method} #{request.path}", data])
      end

      def primary?
        @primary
      end

      def drain
        return unless primary?

        log_entries.each do |args|
          logger.public_send(*args)
        end
      end

      def reset
        Roda::EnhancedLogger::Current.reset
      end
    end
  end
end
