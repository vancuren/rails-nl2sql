# Rails NL2SQL

This gem provides an easy way to integrate natural language to SQL functionality into your Ruby on Rails projects. It uses AI models to convert natural language queries into SQL statements.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-nl2sql'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-nl2sql

Next, you need to run the install generator:

    $ rails generate rails:nl2sql:install

This will create an initializer file at `config/initializers/rails_nl2sql.rb`. You will need to configure your OpenAI API key in this file.

```ruby
# config/initializers/rails_nl2sql.rb
Rails::Nl2sql.configure do |config|
  config.api_key = ENV["OPENAI_API_KEY"] # It's recommended to use an environment variable
  # config.model = "text-davinci-003" # Optional: Specify the AI model to use (default is text-davinci-003)
end
```

Make sure to set the `OPENAI_API_KEY` environment variable in your development and production environments.

## Usage

To execute a natural language query, you can use the `execute` method:

```ruby
results = Rails::Nl2sql::Processor.execute("Show me all the users from California")
```

You can also specify which tables to include or exclude:

```ruby
results = Rails::Nl2sql::Processor.execute("Show me all the orders for the user with email 'test@example.com'", include: ["users", "orders"])
```

### Getting a list of tables

```ruby
Rails::Nl2sql::Processor.get_tables
```

### Getting the schema

```ruby
Rails::Nl2sql::Processor.get_schema(include: ["users", "orders"])
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vancuren/rails-nl2sql.
