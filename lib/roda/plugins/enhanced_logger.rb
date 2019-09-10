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
      InvalidLogger = Class.new(StandardError)

      module InstanceMethods
        def _filter_params(params:, filtered_params:)
          params.each_with_object(params) { |(k, v), obj|
            if v.is_a?(Hash)
              return obj[k] = _filter_params(params: v, filtered_params: filtered_params)
            end

            if filtered_params.include?(k.to_sym)
              obj[k] = "<FILTERED>"
            end
          }
        end
      end

      def self.load_dependencies(app, _opts={}) # :nodoc:
        app.plugin :hooks
        app.plugin :match_hook
      end

      def self.default_filtered_params
        %i[password _csrf]
      end

      def self.default_logger(log_time: false)
        TTY::Logger.new do |config|
          config.metadata = [:date, :time] if log_time
        end
      end

      def self.configure(app,
                         db: nil,
                         log_time: false,
                         logger: default_logger(log_time: log_time),
                         trace_missed: true,
                         trace_all: false,
                         filtered_params: default_filtered_params) # :nodoc:

        raise InvalidLogger, "expected an instance of TTY::Logger" unless logger.kind_of?(TTY::Logger)

        root = Pathname(app.opts[:root] || Dir.pwd)

        db = db || (defined?(DB) && DB)
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
            params: _filter_params(params: request.params, filtered_params: filtered_params)
          }

          if (db = Thread.current[:accrued_database_time])
            data[:db] = db.round(6)
          end

          logger.send(meth, "#{request.request_method} #{request.path}", data)

          if (trace_missed && status == 404) || trace_all
            @_matches.each do |match|
              logger.send(meth, format("  %s (%s:%s)",
                     File.readlines(match.path)[match.lineno - 1].strip.sub(" do", ""),
                     Pathname(match.path).relative_path_from(root),
                     match.lineno))
            end
          end

          Thread.current[:accrued_database_time] = nil
        end
      end
    end

    register_plugin :enhanced_logger, EnhancedLogger # :nodoc:
  end
end
