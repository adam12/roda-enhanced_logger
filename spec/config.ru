require "bundler/setup"
require "roda"
require "sequel"

DB = Sequel.connect("mock://")

app = Class.new(Roda) {
  plugin :enhanced_logger, trace_all: true

  route do |r|
    r.is "foo", method: :get do
      2.times { DB[:table].to_a }

      "foo"
    end

    r.is "bar", method: :get do
      "bar"
    end

    r.on "baz" do
      "baz"
    end

    r.on "a" do
      r.on "b" do
        r.on "c" do
          r.is "d" do
            "a/b/c/d"
          end
        end
      end
    end
  end
}

run app
