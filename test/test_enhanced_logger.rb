require "minitest/autorun"
require "minitest/focus"
require "roda"
require "tty-logger"
require "sequel"

describe "EnhancedLogger" do
  let(:null_logger) {
    TTY::Logger.new do |config|
      config.output = File.open("/dev/null", "a")
    end
  }

  it "logs to stderr by default" do
    assert_output(nil, /./) do
      app = Class.new(Roda) {
        plugin :enhanced_logger

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).get("/")
    end
  end

  it "allows base logger to be provided" do
    logger = Minitest::Mock.new(null_logger)
    logger.expect(:info, true, [String, Hash])

    app = Class.new(Roda) {
      plugin :enhanced_logger, logger: logger

      route do |r|
        "OK"
      end
    }

    response = Rack::MockRequest.new(app).get("/")

    assert_mock logger
  end

  it "expects base logger to be instance of TTY::Logger" do
    assert_raises Roda::RodaPlugins::EnhancedLogger::InvalidLogger do
      Class.new(Roda) {
        plugin :enhanced_logger, logger: Object.new
      }
    end
  end

  describe "database logging" do
    it "allows custom database object" do
      db = Sequel.mock
      logger = null_logger

      app = Class.new(Roda) {
        plugin :enhanced_logger, db: db, logger: logger

        route do |r|
          db[:foos].to_a
          "OK"
        end
      }

      response = Rack::MockRequest.new(app).get("/")

      assert_equal "OK", response.body
      refute_empty db.sqls
    end

    it "records accrued database time" do
      accrued_time = nil
      db = Sequel.mock

      logger = null_logger
      logger.define_singleton_method(:info) { |_, opts={}|
        accrued_time = opts[:db] if opts.key?(:db)
      }

      app = Class.new(Roda) {
        plugin :enhanced_logger, db: db, logger: logger

        route do |r|
          db[:foos].to_a
          "OK"
        end
      }

      response = Rack::MockRequest.new(app).get("/")

      refute_nil accrued_time
    end
  end

  describe "filtered params" do
    it "has a default filtered params list" do
      log_output = StringIO.new

      logger = TTY::Logger.new(output: log_output) do |config|
        config.handlers = [[:stream, formatter: :text]]
      end

      app = Class.new(Roda) {
        plugin :enhanced_logger, logger: logger

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).post("/", params: { password: "secret" })

      assert_match /password=\<FILTERED\>/, log_output.string
    end

    it "allows customization of filtered params list" do
      log_output = StringIO.new

      logger = TTY::Logger.new(output: log_output) do |config|
        config.handlers = [[:stream, formatter: :text]]
      end

      app = Class.new(Roda) {
        plugin :enhanced_logger, filtered_params: %i[first_name],
                                 logger: logger

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).post("/", params: { first_name: "Adam" })

      assert_match /first_name=\<FILTERED\>/, log_output.string
    end

    it "deeply filters params list" do
      log_output = StringIO.new

      logger = TTY::Logger.new(output: log_output) do |config|
        config.handlers = [[:stream, formatter: :text]]
      end

      app = Class.new(Roda) {
        plugin :enhanced_logger, logger: logger

      }

      Rack::MockRequest.new(app).post("/", params: { user: { password: "secret" } })

      assert_match /password=\<FILTERED\>/, log_output.string
    end
  end
end
