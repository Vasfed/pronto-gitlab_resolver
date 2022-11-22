# Pronto::GitlabResolver

Pronto gitlab formatter extension that marks fixed warning threads as resolved.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pronto-github_resolver', require: false
```
The line will probably go into `:lint` group, depending on your setup.

And then execute:
```sh
bundle install
```

Or just:

    $ bundle add pronto-gitlab_resolver


## Usage

Pronto will pick up this from gemfile automatically.
If you already have pronto set up and working with `gitlab_mr` formatter, it should just work.

Note that bot user should not be reused for other MR comments (because this will delete/resolve all other comments that are not returned by linters on current run).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Vasfed/pronto-gitlab_resolver.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
