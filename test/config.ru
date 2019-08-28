require "bundler/setup"
require "roda"
require "sequel"

DB = Sequel.connect("mock://")

app = Class.new(Roda) do
  plugin :enhanced_logger

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
  end
end

run app
