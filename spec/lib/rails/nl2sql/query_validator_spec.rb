require 'spec_helper'
require 'rails/nl2sql/query_validator'

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

  class StatementInvalid < StandardError
  end
end

RSpec.describe Rails::Nl2sql::QueryValidator do
  describe '.validate' do
    let(:connection) { double('ActiveRecord::ConnectionAdapters::AbstractAdapter') }

    before do
      ActiveRecord::Base.connection = connection
    end

    it 'returns true for a valid SELECT query' do
      allow(connection).to receive(:execute).with("EXPLAIN SELECT * FROM users").and_return(true)
      expect(described_class.validate("SELECT * FROM users")).to be true
    end

    it 'raises an error for queries with disallowed keywords' do
      disallowed_queries = [
        "DROP TABLE users",
        "DELETE FROM users",
        "UPDATE users SET name = 'test'",
        "INSERT INTO users (name) VALUES ('test')",
        "TRUNCATE TABLE users",
        "ALTER TABLE users ADD COLUMN age INT",
        "CREATE TABLE users (id INT)"
      ]

      disallowed_queries.each do |query|
        expect { described_class.validate(query) }.to raise_error("Query contains disallowed keywords.")
      end
    end

    it 'raises an error for an invalid SQL query' do
      allow(connection).to receive(:execute).and_raise(ActiveRecord::StatementInvalid.new("Syntax error"))
      expect { described_class.validate("SELECT FROM users") }.to raise_error("Invalid SQL query: Syntax error")
    end
  end
end
