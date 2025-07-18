Rails::Nl2sql.configure do |config|
  # Set your API key. It's recommended to use an environment variable for security.
  config.api_key = ENV["OPENAI_API_KEY"]
  
  # Optional: Set the model to use (default: "gpt-3.5-turbo-instruct")
  # config.model = "gpt-3.5-turbo-instruct"
  
  # Optional: Set a custom provider (default: OpenAI)
  # config.provider = Rails::Nl2sql::Providers::OpenaiProvider.new(api_key: config.api_key)
  # config.provider = Rails::Nl2sql::Providers::AnthropicProvider.new(api_key: ENV["ANTHROPIC_API_KEY"])
  
  # Optional: Set custom prompt template path
  # config.prompt_template_path = Rails.root.join("config", "nl2sql_prompts.yml.erb")
  
  # Optional: Limit schema lines to fit within model context window (default: 200)
  # config.max_schema_lines = 200
end
