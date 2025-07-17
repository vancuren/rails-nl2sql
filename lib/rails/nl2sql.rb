require "rails/nl2sql/version"
require "rails/nl2sql/query_generator"
require "rails/nl2sql/schema_builder"
require "rails/nl2sql/query_validator"

module Rails
  module Nl2sql
    class Error < StandardError; end

    class << self
      attr_accessor :api_key
      attr_accessor :model
    end
    @@model = "text-davinci-003"

    def self.configure
      yield self
    end

    class Processor
      def self.execute(natural_language_query, options = {})
        schema = SchemaBuilder.build_schema(options)
        query_generator = QueryGenerator.new(Rails::Nl2sql.api_key, Rails::Nl2sql.model)
        generated_query = query_generator.generate_query(natural_language_query, schema)

        QueryValidator.validate(generated_query)

        ActiveRecord::Base.connection.execute(generated_query)
      end

      def self.get_tables(options = {})
        ActiveRecord::Base.connection.tables
      end

      def self.get_schema(options = {})
        SchemaBuilder.build_schema(options)
      end
    end
  end
end
