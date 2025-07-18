require 'spec_helper'
require 'rails/nl2sql/schema_builder'

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
  let(:connection) { double('ActiveRecord::ConnectionAdapters::AbstractAdapter', adapter_name: 'PostgreSQL') }
  let(:columns) { [double('column', name: 'id'), double('column', name: 'name')] }

  before do
    ActiveRecord::Base.connection = connection
    allow(connection).to receive(:tables).and_return(['users'])
    allow(connection).to receive(:columns).with('users').and_return(columns)
    described_class.clear_cache!
  end

  it 'caches the schema after first build' do
    described_class.build_schema
    described_class.build_schema
    expect(connection).to have_received(:columns).with('users').once
  end
end
