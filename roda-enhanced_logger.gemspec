Gem::Specification.new do |spec|
  spec.name = "roda-enhanced_logger"
  spec.version = "0.1.0"
  spec.authors = ["Adam Daniels"]
  spec.email = "adam@mediadrive.ca"

  spec.summary = "An enhanced logger for Roda applications"
  spec.homepage = "https://github.com/adam12/roda-enhanced_logger"
  spec.license = "MIT"

  spec.files = ["README.md"] + Dir["lib/**/*.rb"]

  spec.add_dependency "roda", ">= 3.19.0"
  spec.add_dependency "tty-logger", ">= 0.3", "< 1.0"

  spec.required_ruby_version = ">= 2.1"
end
