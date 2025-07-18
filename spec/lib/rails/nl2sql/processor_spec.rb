require 'spec_helper'
require 'rails/nl2sql'

# Define a minimal mock for ActiveRecord::Base and its connection
module ActiveRecord
  class Base
    def self.connection
      @@connection
    end

    def self.connection=(conn)
      @@connection = conn
    end
  end
end

class ActiveRecord::StatementInvalid < StandardError
end

RSpec.describe Rails::Nl2sql::Processor do
  before do
    # Reset configuration before each test
    Rails::Nl2sql.api_key = nil
    Rails::Nl2sql.model = "text-davinci-003"

    # Mock ActiveRecord::Base.connection and its methods
    allow(ActiveRecord::Base).to receive(:connection).and_return(connection)
    allow(connection).to receive(:tables).and_return(['users', 'products'])

    # Mock columns for 'users' table
    user_columns = [
      double('column', name: 'id'),
      double('column', name: 'name'),
      double('column', name: 'email')
    ]
    allow(connection).to receive(:columns).with('users').and_return(user_columns)

    # Mock columns for 'products' table
    product_columns = [
      double('column', name: 'id'),
      double('column', name: 'name'),
      double('column', name: 'price')
    ]
    allow(connection).to receive(:columns).with('products').and_return(product_columns)
  end

  let(:connection) { double('ActiveRecord::ConnectionAdapters::AbstractAdapter') }

  describe '.execute' do
    let(:api_key) { 'test_api_key' }
    let(:model) { 'text-davinci-003' }
    let(:natural_language_query) { 'Show me all the users' }
    let(:generated_sql) { 'SELECT * FROM users' }

    before do
      Rails::Nl2sql.configure do |config|
        config.api_key = api_key
        config.model = model
        config.provider = double('provider')
      end

      allow(Rails::Nl2sql.provider).to receive(:complete).and_return({'choices' => [{'text' => generated_sql}]})

      # Mock connection.execute for the generated SQL
      allow(connection).to receive(:execute).with(generated_sql).and_return(['user1', 'user2'])
      allow(connection).to receive(:execute).with("EXPLAIN #{generated_sql}").and_return(true)
    end

    it 'generates, validates, and executes a SQL query' do
      results = described_class.execute(natural_language_query)
      expect(results).to eq(['user1', 'user2'])
    end

    it 'raises an error for invalid SQL queries' do
      allow(connection).to receive(:execute).with("EXPLAIN #{generated_sql}").and_raise(ActiveRecord::StatementInvalid.new("Syntax error"))
      expect { described_class.execute(natural_language_query) }.to raise_error("Invalid SQL query: Syntax error")
    end

    it 'handles table exclusion' do
      allow(connection).to receive(:tables).and_return(['users'])
      expect(described_class.execute("Show me all the users", exclude: ['products'])).to eq(['user1', 'user2'])
    end

    it 'handles table inclusion' do
      allow(connection).to receive(:tables).and_return(['products'])
      expect(described_class.execute("Show me all the products", include: ['products'])).to eq(['user1', 'user2'])
    end
  end

  describe '.get_tables' do
    it 'returns a list of all tables' do
      expect(described_class.get_tables).to eq(['users', 'products'])
    end
  end

  describe '.get_schema' do
    it 'returns the schema of all tables' do
      expected_schema = {
        'users' => ['id', 'name', 'email'],
        'products' => ['id', 'name', 'price']
      }
      expect(described_class.get_schema).to eq(expected_schema)
    end

    it 'returns the schema excluding specified tables' do
      expected_schema = {
        'users' => ['id', 'name', 'email']
      }
      expect(described_class.get_schema(exclude: ['products'])).to eq(expected_schema)
    end

    it 'returns the schema including only specified tables' do
      expected_schema = {
        'products' => ['id', 'name', 'price']
      }
      expect(described_class.get_schema(include: ['products'])).to eq(expected_schema)
    end
  end
end
