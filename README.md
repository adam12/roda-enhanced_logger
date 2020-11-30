# Roda Enhanced Logger

## Installation

Add this line to your application's Gemfile:

    gem "roda-enhanced_logger"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install roda-enhanced_logger

## Usage

For basic usage, simply enable through the `plugin` mechanism.


```ruby
class App < Roda
  plugin :enhanced_logger
end
```

If you serve assets through Roda, your logs might be fairly noisy, so you can
filter them.

```ruby
plugin :enhanced_logger, filter: ->(path) { path.start_with?("/assets") }
```

By default, EnhancedLogger will attempt to filter passwords and CSRF tokens,
but you can filter other fields too.

```ruby
plugin :enhanced_logger, filtered_params: %w[api_key]
```

If there's a `DB` constant defined for Sequel, EnhancedLogger will automatically
use it, but you can pass in a custom value if necessary.

```ruby
plugin :enhanced_logger, db: Container[:db]
```

During development, a 404 might catch you off guard for a path that you feel should
exist, so it's handy to trace missed routes to aide in debugging.

```ruby
plugin :enhanced_logger, trace_missed: true
```

Or always trace every request.

```ruby
plugin :enhanced_logger, trace_all: true
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adam12/roda-enhanced_logger.

I love pull requests! If you fork this project and modify it, please ping me to see
if your changes can be incorporated back into this project.

That said, if your feature idea is nontrivial, you should probably open an issue to
[discuss it](http://www.igvita.com/2011/12/19/dont-push-your-pull-requests/)
before attempting a pull request.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
