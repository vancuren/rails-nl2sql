require 'net/http'
require 'uri'
require 'json'

module Rails
  module Nl2sql
    module Providers
      class LlamaProvider < Base
        def initialize(endpoint:, model: nil)
          @uri = URI.parse(endpoint)
          @model = model
        end

        def complete(prompt:, **_params)
          http = Net::HTTP.new(@uri.host, @uri.port)
          http.use_ssl = @uri.scheme == 'https'
          response = http.post(@uri.path, {prompt: prompt, model: @model}.to_json, 'Content-Type' => 'application/json')
          JSON.parse(response.body)
        end
      end
    end
  end
end
