begin
  require 'anthropic'
rescue LoadError
  warn 'Anthropic gem not installed; AnthropicProvider will not work'
end

module Rails
  module Nl2sql
    module Providers
      class AnthropicProvider < Base
        def initialize(api_key:, model: 'claude-3-opus-20240229')
          raise 'anthropic gem missing' unless defined?(::Anthropic::Client)
          @client = ::Anthropic::Client.new(api_key: api_key)
          @model = model
        end

        def complete(prompt:, **params)
          @client.completions(model: @model, prompt: prompt, **params)
        end
      end
    end
  end
end
