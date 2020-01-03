require "bundler/setup"
require "roda"
require "tty-logger"
require "sequel"

require "roda/plugins/enhanced_logger"

RSpec.describe Roda::RodaPlugins::EnhancedLogger do
  it "logs to stdout by default" do
    expect {
      app = Class.new(Roda) {
        plugin :enhanced_logger

        route do |r|
          "OK"
        end
      }

      response = Rack::MockRequest.new(app).get("/")
      expect(response.body).to eq("OK")
    }.to output.to_stdout
  end

  describe "database logging" do
    it "allows custom database object" do
      db = Sequel.mock

      app = Class.new(Roda) {
        plugin :enhanced_logger, db: db, output: File.new(File::NULL, "w")

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
      output = StringIO.new
      db = Sequel.mock

      app = Class.new(Roda) {
        plugin :enhanced_logger, db: db, handlers: [[:stream, output: output]]

        route do |r|
          db[:foos].to_a
          "OK"
        end
      }

      Rack::MockRequest.new(app).get("/")

      expect(output.string).to match(/db=\d+/)
    end
  end

  describe "filtered params" do
    it "has a default filtered params list" do
      output = StringIO.new
      app = Class.new(Roda) {
        plugin :enhanced_logger, handlers: [[:stream, output: output]]

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).post("/", params: { password: "secret" })

      expect(output.string).to match(/password=\<FILTERED\>/)
    end

    it "allows customization of filtered params list" do
      output = StringIO.new

      app = Class.new(Roda) {
        plugin :enhanced_logger, filtered_params: %i[first_name],
                                 handlers: [[:stream, output: output]]

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).post("/", params: { first_name: "Adam" })

      expect(output.string).to match(/first_name=\<FILTERED\>/)
    end

    it "deeply filters params list" do
      output = StringIO.new
      app = Class.new(Roda) {
        plugin :enhanced_logger, handlers: [[:stream, output: output]]

        route do |r|
          "OK"
        end
      }

      Rack::MockRequest.new(app).post("/", params: { user: { password: "secret" } })

      expect(output.string).to match(/\password=<FILTERED\>/)
    end
  end
end
