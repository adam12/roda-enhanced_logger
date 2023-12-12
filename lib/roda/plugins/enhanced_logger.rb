# frozen-string-literal: true

require "pathname"
require "tty-logger"
require "roda/enhanced_logger/current"
require "roda/enhanced_logger/instance"

class Roda
  module RodaPlugins
    # The +enhanced_logger+ plugin provides a coloured, single line log
    # entry for requests in a Roda application.
    #
    # Some interesting pieces of the log entry include which line matched the request,
    # any time incurred by Sequel DB queries, and the remaining path that might have
    # not been matched.
    #
    # It's mostly suitable in development but would likely be fine in production.
    #
    # @example Basic configuration
    #   plugin :enhanced_logger
    #
    # @example Filter requests to assets
    #   plugin :enahanced_logger, filter: ->(path) { path.start_with?("/assets") }
    #
    # @example Filter parameters
    #   plugin :enhanced_logger, filtered_params: %i[api_key]
    #
    # @example Log date and time of request
    #   plugin :enhanced_logger, log_time: true
    module EnhancedLogger
      DEFAULTS = {
        db: nil,
        log_time: false,
        trace_missed: true,
        trace_all: false,
        filtered_params: %w[password password_confirmation _csrf],
        handlers: [:console]
      }.freeze

      def self.load_dependencies(app, _opts = {})
        app.plugin :hooks
        app.plugin :match_hook
      end

      def self.configure(app, opts = {})
        options = DEFAULTS.merge(opts)

        logger = TTY::Logger.new { |config|
          config.handlers = options[:handlers]
          config.output = options.fetch(:output) { $stdout }
          config.metadata.push(:time, :date) if options[:log_time]
          config.filters.data = options[:filtered_params]
          config.filters.mask = "<FILTERED>"
        }

        root = Pathname(app.opts[:root] || Dir.pwd)

        db = options[:db] || (defined?(DB) && DB)
        db&.extension :enhanced_logger

        app.match_hook do
          callee = caller_locations.find { |location|
            location.path.start_with?(root.to_s)
          }

          @_enhanced_logger_instance.add_match(callee)
        end

        app.before do
          @_enhanced_logger_instance = Roda::EnhancedLogger::Instance.new(logger, env, object_id, root, options[:filter])
        end

        app.after do |res|
          status, _ = res
          @_enhanced_logger_instance.add(
            status,
            request,
            (options[:trace_missed] && status == 404) || options[:trace_all]
          )

          @_enhanced_logger_instance.drain
          @_enhanced_logger_instance.reset
        end
      end
    end

    register_plugin :enhanced_logger, EnhancedLogger
  end
end
