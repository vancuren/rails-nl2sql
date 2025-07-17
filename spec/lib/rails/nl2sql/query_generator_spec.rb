require 'spec_helper'
require 'rails/nl2sql/query_generator'

RSpec.describe Rails::Nl2sql::QueryGenerator do
  describe '#generate_query' do
    it 'generates a SQL query from a natural language prompt' do
      api_key = 'test_api_key'
      model = 'text-davinci-003'
      prompt = 'Show me all the users'
      schema = { users: ['id', 'name', 'email'] }

      client = double('OpenAI::Client')
      allow(OpenAI::Client).to receive(:new).with(api_key: api_key).and_return(client)

      response = double('response', choices: [double('choice', text: 'SELECT * FROM users')])
      allow(client).to receive(:completions).with(
        parameters: {
          model: model,
          prompt: "Given the following schema:\n\n#{schema}\n\nGenerate a SQL query for the following request:\n\n#{prompt}",
          max_tokens: 150
        }
      ).and_return(response)

      query_generator = described_class.new(api_key, model)
      generated_query = query_generator.generate_query(prompt, schema)

      expect(generated_query).to eq('SELECT * FROM users')
    end
  end
end