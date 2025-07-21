require "erb"
require "yaml"
require "rails/nl2sql/prompt_builder"

module Rails
  module Nl2sql
    class QueryGenerator
      DEFAULT_MODEL = 'gpt-3.5-turbo-instruct'

      # Initializes a new QueryGenerator.
      #
      # @param provider [Object] The AI provider to use for generating queries.
      # @param model [String] The name of the AI model to use.
      def initialize(provider: nil, model: DEFAULT_MODEL)
        @provider = provider || Rails::Nl2sql.provider || default_provider(model)
        @model = model
      end

      # Generates a SQL query from a natural language prompt.
      #
      # @param prompt [String] The natural language prompt.
      # @param schema [String] The database schema.
      # @param db_server [String] The type of database server.
      # @param tables [Array<String>] The tables to include in the schema.
      # @return [String] The generated SQL query.
      def generate_query(prompt, schema, db_server = 'PostgreSQL', tables = nil)
        retrieved_context = build_context(schema, tables)

        full_prompt = PromptBuilder.build(prompt, db_server, retrieved_context)

        response = @provider.complete(prompt: full_prompt, max_tokens: 500, temperature: 0.1)
        generated_query = extract_text(response)

        generated_query = clean_sql_response(generated_query)
        validate_query_safety(generated_query)

        generated_query
      end

      private

      # Returns the default AI provider.
      #
      # @param model [String] The name of the AI model to use.
      # @return [Object] The default AI provider.
      def default_provider(model)
        Providers::OpenaiProvider.new(api_key: Rails::Nl2sql.api_key, model: model)
      end

      # Extracts the text from the AI provider's response.
      #
      # @param response [Object] The response from the AI provider.
      # @return [String] The extracted text.
      def extract_text(response)
        if response.is_a?(Hash)
          response.dig('choices', 0, 'text')&.strip
        else
          nil
        end
      end

      # Builds the context for the AI prompt.
      #
      # @param schema [String] The database schema.
      # @param tables [Array<String>] The tables to include in the schema.
      # @return [String] The context for the AI prompt.
      def build_context(schema, tables)
        context = if tables&.any?
          filter_schema_by_tables(schema, tables)
        else
          schema
        end
        apply_context_window(context)
      end

      # Applies the context window to the context.
      #
      # @param context [String] The context for the AI prompt.
      # @return [String] The context with the context window applied.
      def apply_context_window(context)
        max_lines = Rails::Nl2sql.max_schema_lines
        return context unless max_lines

        lines = context.split("\n")
        return context if lines.length <= max_lines

        lines.first(max_lines).join("\n")
      end

      # Filters the schema by the given tables.
      #
      # @param schema [String] The database schema.
      # @param tables [Array<String>] The tables to include in the schema.
      # @return [String] The filtered schema.
      def filter_schema_by_tables(schema, tables)
        lines = schema.split("\n")
        filtered_lines = []
        current_table = nil
        include_current = false

        lines.each do |line|
          if line.match(/CREATE TABLE (\w+)/)
            current_table = Regexp.last_match(1)
            include_current = tables.include?(current_table)
          end

          filtered_lines << line if include_current || line.strip.empty?
        end

        filtered_lines.join("\n")
      end

      # Cleans the SQL response from the AI provider.
      #
      # @param query [String] The SQL query to clean.
      # @return [String] The cleaned SQL query.
      def clean_sql_response(query)
        return query unless query

        query = query.gsub(/```sql\n?/, '')
        query = query.gsub(/```\n?/, '')
        query = query.strip
        query = query.gsub(/^(.*?)(SELECT|WITH|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)/i, '\1')
        lines = query.split("\n")
        sql_lines = []

        lines.each do |line|
          line = line.strip
          next if line.empty?
          next if line.match(/^(here|this|the query|explanation|note)/i)

          sql_lines << line
        end

        cleaned_query = sql_lines.join("\n").strip
        cleaned_query += ';' if cleaned_query.match(/^(SELECT|WITH)/i) && !cleaned_query.end_with?(';')
        cleaned_query
      end

      # Validates the safety of the SQL query.
      #
      # @param query [String] The SQL query to validate.
      def validate_query_safety(query)
        return unless query

        banned_keywords = %w[delete drop truncate update insert alter exec execute create merge replace into]
        banned_phrases = [
          'ignore previous instructions', 'pretend you are', 'i am the admin',
          'you are no longer bound', 'bypass the rules', 'run this instead',
          'for testing, run', 'no safety constraints', 'show me a dangerous query',
          'this is a dev environment', 'drop all data', 'delete all users', 'wipe the database'
        ]

        query_lower = query.downcase
        banned_keywords.each do |keyword|
          raise Rails::Nl2sql::Error, "Query contains banned keyword: #{keyword}" if query_lower.include?(keyword)
        end
        banned_phrases.each do |phrase|
          raise Rails::Nl2sql::Error, "Query contains banned phrase: #{phrase}" if query_lower.include?(phrase)
        end
      end
    end
  end
end
