# frozen-string-literal: true

require "roda"
require "sequel"

DB = Sequel.mock

class App < Roda
  plugin :enhanced_logger,
    filter: ->(path) { path.start_with?("/favicon.ico") },
    trace_missed: true

  route do |r|
    r.on "foo" do
      r.on "bar" do
        r.is "baz" do
          "foo/bar/baz"
        end
      end
    end

    r.root do
      DB[:foos].to_a
      "OK"
    end
  end
end

run App
