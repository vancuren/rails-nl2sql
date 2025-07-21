require 'spec_helper'
require 'rails/nl2sql/providers/gemini_provider'

RSpec.describe Rails::Nl2sql::Providers::GeminiProvider do
  describe '#initialize' do
    it 'initializes with an api_key' do
      provider = described_class.new(api_key: 'test_api_key')
      expect(provider).to be_a(described_class)
    end
  end
end
