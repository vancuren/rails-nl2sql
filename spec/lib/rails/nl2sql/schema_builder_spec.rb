require 'spec_helper'
require 'rails/nl2sql/schema_builder'

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

RSpec.describe Rails::Nl2sql::SchemaBuilder do
  describe '.build_schema' do
    let(:connection) { double('ActiveRecord::ConnectionAdapters::AbstractAdapter') }

    before do
      ActiveRecord::Base.connection = connection
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

    it 'builds a schema hash with all tables and their columns by default' do
      expected_schema = {
        'users' => ['id', 'name', 'email'],
        'products' => ['id', 'name', 'price']
      }
      expect(described_class.build_schema).to eq(expected_schema)
    end

    it 'builds a schema hash excluding specified tables' do
      expected_schema = {
        'users' => ['id', 'name', 'email']
      }
      expect(described_class.build_schema(exclude: ['products'])).to eq(expected_schema)
    end

    it 'builds a schema hash including only specified tables' do
      expected_schema = {
        'products' => ['id', 'name', 'price']
      }
      expect(described_class.build_schema(include: ['products'])).to eq(expected_schema)
    end
  end
end
