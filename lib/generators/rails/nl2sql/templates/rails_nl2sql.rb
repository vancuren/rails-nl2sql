Rails::Nl2sql.configure do |config|
  config.api_key = "YOUR_API_KEY"
  # config.model = "gpt-3.5-turbo-instruct"
  # config.provider = Rails::Nl2sql::Providers::OpenaiProvider.new(api_key: config.api_key)
  # config.prompt_template_path = Rails::Nl2sql.prompt_template_path
  # config.max_schema_lines = 200
end
