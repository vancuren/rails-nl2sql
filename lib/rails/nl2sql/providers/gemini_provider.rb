require 'google/apis/aiplatform_v1'

module Rails
  module Nl2sql
    module Providers
      class GeminiProvider < Base
        def initialize(api_key:, model: 'gemini-pro')
          # Authenticate with Google Cloud
          # You can use a service account or your user credentials.
          # For more information, see: https://cloud.google.com/docs/authentication
          Google::Auth.new.apply(scope: 'https://www.googleapis.com/auth/cloud-platform')

          @client = Google::Apis::AiplatformV1::AIPlatformService.new
          @model = model
        end

        def complete(prompt:, **params)
          # The Gemini API uses a different request format than the other providers.
          # We need to convert the prompt into a format that the Gemini API can understand.
          request = Google::Apis::AiplatformV1::GoogleCloudAiplatformV1PredictRequest.new(
            instances: [
              {
                prompt: prompt
              }
            ],
            parameters: {
              temperature: params[:temperature] || 0.2,
              maxOutputTokens: params[:max_tokens] || 256,
              topP: params[:top_p] || 0.95,
              topK: params[:top_k] || 40
            }
          )

          # The endpoint for the Gemini API is different for each region.
          # We need to get the endpoint for the region that the user is in.
          # For more information, see: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models
          endpoint = 'us-central1-aiplatform.googleapis.com' # Or another regional endpoint

          response = @client.predict_project_location_publisher_model(endpoint, request)

          # The Gemini API returns a different response format than the other providers.
          # We need to convert the response into a format that the other providers can understand.
          response.predictions.first['content']
        end
      end
    end
  end
end
