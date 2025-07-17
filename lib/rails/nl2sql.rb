require "rails/nl2sql/version"
require "rails/nl2sql/query_generator"
require "rails/nl2sql/schema_builder"
require "rails/nl2sql/query_validator"
require "rails/nl2sql/railtie" if defined?(Rails)

module Rails
  module Nl2sql
    class Error < StandardError; end

    class << self
      attr_accessor :api_key
      attr_accessor :model
    end
    @@model = "gpt-3.5-turbo-instruct"

    def self.configure
      yield self
    end

    class Processor
      def self.execute(natural_language_query, options = {})
        # Get database type
        db_server = SchemaBuilder.get_database_type
        
        # Build schema with optional table filtering
        schema = SchemaBuilder.build_schema(options)
        
        # Debug: Show what schema is being built
        puts "=== RAW SCHEMA FROM BUILDER ==="
        puts schema
        puts "=== END RAW SCHEMA ==="
        
        # Extract tables for filtering if specified
        tables = options[:tables]
        
        # Generate query with enhanced prompt
        query_generator = QueryGenerator.new(Rails::Nl2sql.api_key, Rails::Nl2sql.model)
        generated_query = query_generator.generate_query(
          natural_language_query, 
          schema, 
          db_server, 
          tables
        )

        # Validate the generated query
        QueryValidator.validate(generated_query)

        # Execute the query
        ActiveRecord::Base.connection.execute(generated_query)
      end

      def self.generate_query_only(natural_language_query, options = {})
        # Get database type
        db_server = SchemaBuilder.get_database_type
        
        # Build schema with optional table filtering
        schema = SchemaBuilder.build_schema(options)
        
        # Extract tables for filtering if specified
        tables = options[:tables]
        
        # Generate query with enhanced prompt
        query_generator = QueryGenerator.new(Rails::Nl2sql.api_key, Rails::Nl2sql.model)
        generated_query = query_generator.generate_query(
          natural_language_query, 
          schema, 
          db_server, 
          tables
        )

        # Validate the generated query
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
