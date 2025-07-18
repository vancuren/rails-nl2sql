require 'openai'

module Rails
  module Nl2sql
    module Providers
      class OpenaiProvider < Base
        def initialize(api_key:, model: 'gpt-3.5-turbo-instruct')
          @client = ::OpenAI::Client.new(access_token: api_key)
          @model = model
        end

        def complete(prompt:, **params)
          @client.completions(parameters: {model: @model, prompt: prompt}.merge(params))
        end
      end
    end
  end
end
