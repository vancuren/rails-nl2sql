require "rails/nl2sql/version"
require "rails/nl2sql/providers/base"
require "rails/nl2sql/providers/openai_provider"
require "rails/nl2sql/providers/anthropic_provider"
require "rails/nl2sql/providers/llama_provider"
require "rails/nl2sql/query_generator"
require "rails/nl2sql/schema_builder"
require "rails/nl2sql/query_validator"
require "rails/nl2sql/active_record_extension"
require "rails/nl2sql/railtie" if defined?(Rails)
require 'yaml'
require 'erb'

module Rails
  module Nl2sql
    class Error < StandardError; end

    class << self
      attr_accessor :api_key
      attr_accessor :model
      attr_accessor :provider
      attr_accessor :max_schema_lines

      def prompt_template_path=(path)
        @prompt_template = nil
        @prompt_template_path = path
      end

      def prompt_template_path
        @prompt_template_path || File.expand_path('nl2sql/prompts/default.yml.erb', __dir__)
      end
    end

    @model = 'gpt-3.5-turbo-instruct'
    @max_schema_lines = 200

    def self.configure
      yield self
    end

    def self.prompt_template
      # Load the YAML template without evaluating ERB so we can
      # interpolate variables later when building prompts.
      @prompt_template ||= YAML.safe_load(File.read(prompt_template_path))
    end

    class Processor
      def self.execute(natural_language_query, options = {})
        db_server = SchemaBuilder.get_database_type
        schema = SchemaBuilder.build_schema(options)
        tables = options[:tables]

        query_generator = QueryGenerator.new(model: Rails::Nl2sql.model)
        generated_query = query_generator.generate_query(
          natural_language_query,
          schema,
          db_server,
          tables
        )

        QueryValidator.validate(generated_query)
        ActiveRecord::Base.connection.execute(generated_query)
      end

      def self.generate_query_only(natural_language_query, options = {})
        db_server = SchemaBuilder.get_database_type
        schema = SchemaBuilder.build_schema(options)
        tables = options[:tables]

        query_generator = QueryGenerator.new(model: Rails::Nl2sql.model)
        generated_query = query_generator.generate_query(
          natural_language_query,
          schema,
          db_server,
          tables
        )

        QueryValidator.validate(generated_query)
        generated_query
      end

      def self.get_tables(options = {})
        SchemaBuilder.get_filtered_tables(options)
      end

      def self.get_schema(options = {})
        SchemaBuilder.build_schema(options)
      end

      def self.get_database_type
        SchemaBuilder.get_database_type
      end
    end
  end
end
