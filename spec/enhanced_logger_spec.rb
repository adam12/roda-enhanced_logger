require "bundler/setup"
require "roda"
require "tty-logger"
require "sequel"

require "roda/plugins/enhanced_logger"

RSpec.describe Roda::RodaPlugins::EnhancedLogger do
  let(:null_logger) { TTY::Logger.new(output: File.open("/dev/null", "a")) }

  it "logs to stderr by default" do
    app = Class.new(Roda) {
      plugin :enhanced_logger

      route do |r|
        "OK"
      end
    }

    expect {
      Rack::MockRequest.new(app).get("/")
    }.to output(/./).to_stderr
  end

  it "allows base logger to be provided" do
    logger = null_logger

    app = Class.new(Roda) {
      plugin :enhanced_logger, logger: logger

      route do |r|
        "OK"
      end
    }

    Rack::MockRequest.new(app).get("/")
  end

  it "expects base logger to be instance of TTY::Logger" do
    expect {
      Class.new(Roda) {
        plugin :enhanced_logger, logger: Object.new
      }
    }.to raise_exception(Roda::RodaPlugins::EnhancedLogger::InvalidLogger)
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

      expect(response.body).to eq("OK")
      expect(db.sqls).to_not be_empty
    end

    it "records accrued database time" do
      accrued_time = nil
      db = Sequel.mock

      logger = TTY::Logger.new
      expect(logger).to receive(:info) { |_, opts={}|
        accrued_time = opts[:db] if opts.key?(:db)
      }

      app = Class.new(Roda) {
        plugin :enhanced_logger, db: db, logger: logger

        route do |r|
          db[:foos].to_a
          "OK"
        end
      }

      _response = Rack::MockRequest.new(app).get("/")

      expect(accrued_time).to_not be_nil
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

      expect(log_output.string).to match(/password=\<FILTERED\>/)
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

      expect(log_output.string).to match(/first_name=\<FILTERED\>/)
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

      expect(log_output.string).to match(/password=\<FILTERED\>/)
    end
  end
end
