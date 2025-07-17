require 'spec_helper'
require 'rails/nl2sql'

# Minimal mock ActiveRecord setup
module ActiveRecord
  class Base
    def self.connection
      @@connection
    end

    def self.connection=(conn)
      @@connection = conn
    end

    def self.from(sql)
      ActiveRecord::Relation.new
    end
  end

  class Relation
  end
end

class User < ActiveRecord::Base; end

RSpec.describe Rails::Nl2sql::ActiveRecordExtension do
  let(:connection) { double('ActiveRecord::ConnectionAdapters::AbstractAdapter', adapter_name: 'PostgreSQL') }

  before do
    ActiveRecord::Base.connection = connection
    allow(connection).to receive(:tables).and_return(['users'])
    allow(connection).to receive(:columns).with('users').and_return([double('column', name: 'id'), double('column', name: 'name')])

    Rails::Nl2sql.api_key = 'test'
    Rails::Nl2sql.model = 'text-davinci-003'
  end

  it 'returns an ActiveRecord::Relation from natural language' do
    allow(Rails::Nl2sql::Processor).to receive(:generate_query_only).with('all users', {}).and_return('SELECT * FROM users')
    relation = User.from_nl('all users')
    expect(relation).to be_a(ActiveRecord::Relation)
  end
end
