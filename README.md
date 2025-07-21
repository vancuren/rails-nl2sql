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
  # config.model = "gpt-3.5-turbo-instruct" # Optional
  # config.provider = Rails::Nl2sql::Providers::OpenaiProvider.new(api_key: config.api_key)
  # config.prompt_template_path = Rails::Nl2sql.prompt_template_path
  # config.max_schema_lines = 200
end
```

Make sure to set the `OPENAI_API_KEY` environment variable in your development and production environments.

## Usage

To execute a natural language query, you can use the `execute` method:

```ruby
results = Rails::Nl2sql::Processor.execute("Show me all the users from California")
```

### Using `from_nl` with ActiveRecord

You can call the NL2SQL processor directly on your models. The `from_nl` method
returns an `ActiveRecord::Relation` so you can chain scopes, pagination and
other query modifiers as usual.

```ruby
# Get all users who signed up last week and limit the results to 10.
User.from_nl("all users who signed up last week").limit(10)

# Get all users from California and order them by their name.
User.from_nl("all users from california").order(:name)

# Get all users who have an order with a total greater than 100.
User.from_nl("all users who have an order with a total greater than 100")
```

You can also specify which tables to include or exclude:

```ruby
# Get all the orders for the user with email 'test@example.com', but only include the `users` and `orders` tables.
results = Rails::Nl2sql::Processor.execute("Show me all the orders for the user with email 'test@example.com'", include: ["users", "orders"])

# Get all the orders for the user with email 'test@example.com', but exclude the `payments` table.
results = Rails::Nl2sql::Processor.execute("Show me all the orders for the user with email 'test@example.com'", exclude: ["payments"])
```

### Getting a list of tables

```ruby
Rails::Nl2sql::Processor.get_tables
```

### Getting the schema

```ruby
Rails::Nl2sql::Processor.get_schema(include: ["users", "orders"])
```

### Schema caching

For efficiency the gem caches the full database schema on first use. The cached
schema is reused for subsequent requests so your application doesn't need to hit
the database every time a prompt is generated.

You can clear the cached schema if your database changes:

```ruby
Rails::Nl2sql::SchemaBuilder.clear_cache!
```

## Pluggable LLM Providers

Rails NL2SQL ships with a simple adapter system so you can use different large language model providers.
By default the gem uses OpenAI, but you can plug in others like Anthropic or a local Llama‑based HTTP endpoint.

```ruby
Rails::Nl2sql.configure do |config|
  config.provider = Rails::Nl2sql::Providers::AnthropicProvider.new(api_key: ENV['ANTHROPIC_KEY'])
end
```

### Llama

You can also use a local Llama-based HTTP endpoint. You'll need to have a local Llama server running.

```ruby
Rails::Nl2sql.configure do |config|
  config.provider = Rails::Nl2sql::Providers::LlamaProvider.new(endpoint: "http://localhost:8080/completion")
end
```

### Google Gemini

You can also use Google's Gemini models. You'll need to have the `google-apis-aiplatform_v1` gem installed and be authenticated with Google Cloud.

```ruby
Rails::Nl2sql.configure do |config|
  config.provider = Rails::Nl2sql::Providers::GeminiProvider.new(api_key: ENV['GOOGLE_API_KEY'])
end
```

## Prompt Templates

The prompts used to talk to the LLM are defined in a YAML/ERB template. You can override this template
to enforce your own naming conventions or add company specific instructions.

```yaml
system: |
  Custom system prompt text...
user: |
  Query: <%= input %>
```

Set the path via `config.prompt_template_path`.

## Context Window Management

Large schemas can exceed the model context window. Use `config.max_schema_lines` to automatically truncate
the schema snippet sent to the model. Only the first N lines are included.

## Debug Mode

This gem provides a debug mode for troubleshooting problems. When debug mode is enabled, the gem will log information about the queries that are being generated, the schema that is being used, and more.

To enable debug mode, set the `debug` option to `true` in your initializer file:

```ruby
# config/initializers/rails_nl2sql.rb
Rails::Nl2sql.configure do |config|
  config.debug = true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Command-Line Interface (CLI)

This gem provides a command-line interface (CLI) for interacting with the NL2SQL processor.

### `query`

Converts a natural language query to SQL.

```bash
$ rails-nl2sql query "Show me all the users from California"
```

### `schema`

Displays the database schema.

```bash
$ rails-nl2sql schema
```

### `tables`

Displays the database tables.

```bash
$ rails-nl2sql tables
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vancuren/rails-nl2sql.
