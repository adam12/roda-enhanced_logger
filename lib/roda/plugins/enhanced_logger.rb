# frozen-string-literal: true

require "tty-logger"

class Roda # :nodoc:
  module RodaPlugins # :nodoc:
    # The enhanced_logger plugin provides a coloured, single line log
    # entry for requests in a Roda application.
    #
    # Some interesting pieces of the log entry include which line matched the request,
    # any time incurred by Sequel DB queries, and the remaining path that might have
    # not been matched.
    #
    # It's mostly suitable in development but would likely be fine in production.
    #
    # = Usage
    #
    #   plugin :enhanced_logger
    #
    module EnhancedLogger
      DEFAULTS = {
        db: nil,
        log_time: false,
        trace_missed: true,
        trace_all: false,
        filtered_params: %w[password _csrf],
        handlers: [:console]
      }.freeze

      def self.load_dependencies(app, _opts={}) # :nodoc:
        app.plugin :hooks
        app.plugin :match_hook
      end

      def self.configure(app, opts={})
        options = DEFAULTS.merge(opts)

        logger = TTY::Logger.new do |config|
          config.handlers = options[:handlers]
          config.output = options.fetch(:output) { $stdout }
          config.metadata = [:data, :time] if options[:log_time]
          config.filters.data = options[:filtered_params].map(&:to_s)
          config.filters.mask = "<FILTERED>"
        end

        root = Pathname(app.opts[:root] || Dir.pwd)

        db = options[:db] || (defined?(DB) && DB)
        if db
          db.extension :enhanced_logger
        end

        app.match_hook do
          callee = caller_locations.find { |location|
            location.path.start_with?(root.to_s)
          }

          @_matches << callee
        end

        app.before do
          @_matches = []
          @_timer = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        app.after do |res|
          status ,= res

          if (last_matched_caller = @_matches.last)
            handler = format("%s:%d",
                             Pathname(last_matched_caller.path).relative_path_from(root),
                             last_matched_caller.lineno)
          end

          meth = case status
                 when 400..499
                   :warn
                 when 500..599
                   :error
                 else
                   :info
                 end

          data = {
            duration: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @_timer).round(4),
            status: status,
            verb: request.request_method,
            path: request.path,
            remaining_path: request.remaining_path,
            handler: handler,
            params: request.params
          }

          if (db = Thread.current[:accrued_database_time])
            data[:db] = db.round(6)
          end

          if (query_count = Thread.current[:database_query_count])
            data[:db_queries] = query_count
          end

          logger.public_send(meth, "#{request.request_method} #{request.path}", data)

          if (options[:trace_missed] && status == 404) || options[:trace_all]
            @_matches.each do |match|
              logger.send(meth, format("  %s (%s:%s)",
                     File.readlines(match.path)[match.lineno - 1].strip.sub(" do", ""),
                     Pathname(match.path).relative_path_from(root),
                     match.lineno))
            end
          end

          Thread.current[:accrued_database_time] = nil
          Thread.current[:database_query_count] = nil
        end
      end
    end

    register_plugin :enhanced_logger, EnhancedLogger # :nodoc:
  end
end
