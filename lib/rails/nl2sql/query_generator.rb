require "erb"
require "yaml"
module Rails
  module Nl2sql
    class QueryGenerator
      DEFAULT_MODEL = 'gpt-3.5-turbo-instruct'

      def initialize(provider: nil, model: DEFAULT_MODEL)
        @provider = provider || Rails::Nl2sql.provider || default_provider(model)
        @model = model
      end

      def generate_query(prompt, schema, db_server = 'PostgreSQL', tables = nil)
        retrieved_context = build_context(schema, tables)

        system_prompt, user_prompt = build_prompts(prompt, db_server, retrieved_context)
        full_prompt = "#{system_prompt}\n\n#{user_prompt}"

        response = @provider.complete(prompt: full_prompt, max_tokens: 500, temperature: 0.1)
        generated_query = extract_text(response)

        generated_query = clean_sql_response(generated_query)
        validate_query_safety(generated_query)

        generated_query
      end

      private

      def default_provider(model)
        Providers::OpenaiProvider.new(api_key: Rails::Nl2sql.api_key, model: model)
      end

      def extract_text(response)
        if response.is_a?(Hash)
          response.dig('choices', 0, 'text')&.strip
        else
          nil
        end
      end

      def build_context(schema, tables)
        context = if tables&.any?
          filter_schema_by_tables(schema, tables)
        else
          schema
        end
        apply_context_window(context)
      end

      def apply_context_window(context)
        max_lines = Rails::Nl2sql.max_schema_lines
        return context unless max_lines

        lines = context.split("\n")
        return context if lines.length <= max_lines

        lines.first(max_lines).join("\n")
      end

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

      def build_prompts(input, db_server, retrieved_context)
        template = Rails::Nl2sql.prompt_template
        template_binding = binding
        system_prompt = ERB.new(template['system']).result(template_binding)
        user_prompt = ERB.new(template['user']).result(template_binding)
        [system_prompt, user_prompt]
      end

      def clean_sql_response(query)
        return query unless query

        query = query.gsub(/```sql\n?/, '')
        query = query.gsub(/```\n?/, '')
        query = query.strip
        query = query.gsub(/^.*?(SELECT|WITH|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)/i, '\1')
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
