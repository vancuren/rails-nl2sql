module Rails
  module Nl2sql
    class QueryValidator
      def self.validate(query)
        return false unless query && !query.strip.empty?
        
        # Clean the query first
        query = query.strip
        
        # Check if query is malformed (contains markdown or other formatting)
        if query.include?('```') || query.include?('```sql')
          raise Rails::Nl2sql::Error, "Query contains markdown formatting and could not be cleaned properly"
        end
        
        # Basic validation: prevent destructive commands
        disallowed_keywords = %w(DROP DELETE UPDATE INSERT TRUNCATE ALTER CREATE EXEC EXECUTE MERGE REPLACE)
        query_upper = query.upcase

        if disallowed_keywords.any? { |keyword| query_upper.include?(keyword) }
          raise Rails::Nl2sql::Error, "Query contains disallowed keywords."
        end

        # Ensure there is only a single statement
        cleaned_query = query.rstrip
        cleaned_query = cleaned_query.chomp(';')
        if cleaned_query.include?(';')
          raise Rails::Nl2sql::Error, "Query contains multiple statements."
        end

        # Ensure it's a SELECT query
        unless query_upper.strip.start_with?('SELECT', 'WITH')
          raise Rails::Nl2sql::Error, "Only SELECT queries are allowed."
        end

        # Use Rails' built-in validation with EXPLAIN
        begin
          # Remove trailing semicolon for EXPLAIN
          explain_query = query.gsub(/;\s*$/, '')
          ActiveRecord::Base.connection.execute("EXPLAIN #{explain_query}")
        rescue ActiveRecord::StatementInvalid => e
          raise Rails::Nl2sql::Error, "Invalid SQL query: #{e.message}"
        end

        true
      end
    end
  end
end
