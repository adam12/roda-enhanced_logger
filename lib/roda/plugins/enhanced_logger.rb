require "tty-logger"

class Roda
  module RodaPlugins
    module EnhancedLogger
      def self.load_dependencies(app)
        app.plugin :hooks
        app.plugin :match_hook
      end

      def self.configure(app)
        logger = TTY::Logger.new do |config|
          config.metadata = [:date, :time]
        end

        root = Pathname(app.opts[:root] || Dir.pwd)

        app.match_hook do
          @_last_matched_caller = caller_locations.find { |location|
            location.path.start_with?(root.to_s)
          }
        end

        app.before do
          @_timer = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        app.after do |res|
          status ,= res

          if @_last_matched_caller
            handler = format("%s:%d",
                             Pathname(@_last_matched_caller.path).relative_path_from(root),
                             @_last_matched_caller.lineno)
          end

          meth = case status
                 when 400..499
                   :warn
                 when 500..599
                   :error
                 else
                   :info
                 end

          logger.send(meth, "#{request.request_method} #{request.path}", {
            duration: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - @_timer).round(4),
            status: status,
            verb: request.request_method,
            path: request.path,
            handler: handler,
            params: request.params
          })
        end
      end
    end

    register_plugin :enhanced_logger, EnhancedLogger
  end
end
