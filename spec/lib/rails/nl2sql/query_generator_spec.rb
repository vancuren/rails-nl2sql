require 'spec_helper'
require 'rails/nl2sql/query_generator'

RSpec.describe Rails::Nl2sql::QueryGenerator do
  describe '#generate_query' do
    it 'generates a SQL query from a natural language prompt' do
      model = 'gpt-3.5-turbo-instruct'
      prompt = 'Show me all the users'
      schema = "CREATE TABLE users (id INT);"

      provider = double('provider')
      allow(provider).to receive(:complete).and_return({'choices' => [{'text' => 'SELECT * FROM users'}]})

      query_generator = described_class.new(provider: provider, model: model)
      generated_query = query_generator.generate_query(prompt, schema)
      
      expect(generated_query).to eq('SELECT * FROM users')
    end
  end
end