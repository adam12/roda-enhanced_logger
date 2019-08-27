require "bundler/setup"
require "roda"

app = Class.new(Roda) do
  plugin :enhanced_logger

  route do |r|
    r.is "foo", method: :get do
      "foo"
    end

    r.is "bar", method: :get do
      "bar"
    end
  end
end

run app
