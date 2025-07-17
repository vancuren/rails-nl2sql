require "openai"

module Rails
  module Nl2sql
    class QueryGenerator
      def initialize(api_key, model = "text-davinci-003")
        @client = OpenAI::Client.new(api_key: api_key)
        @model = model
      end

      def generate_query(prompt, schema)
        full_prompt = "Given the following schema:\n\n#{schema}\n\nGenerate a SQL query for the following request:\n\n#{prompt}"

        response = @client.completions(
          parameters: {
            model: @model,
            prompt: full_prompt,
            max_tokens: 150
          }
        )

        response.choices.first.text.strip
      end
    end
  end
end
