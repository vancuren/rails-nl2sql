require 'thor'
require 'rails/nl2sql'

module Rails
  module Nl2sql
    class CLI < Thor
      desc "query [NATURAL_LANGUAGE_QUERY]", "Converts a natural language query to SQL"
      def query(natural_language_query)
        puts Rails::Nl2sql::Processor.generate_query_only(natural_language_query)
      end

      desc "schema", "Displays the database schema"
      def schema
        puts Rails::Nl2sql::Processor.get_schema
      end

      desc "tables", "Displays the database tables"
      def tables
        puts Rails::Nl2sql::Processor.get_tables
      end
    end
  end
end
