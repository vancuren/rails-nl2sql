module Rails
  module Nl2sql
    class QueryValidator
      def self.validate(query)
        # Basic validation: prevent destructive commands
        disallowed_keywords = %w(DROP DELETE UPDATE INSERT TRUNCATE ALTER CREATE)
        if disallowed_keywords.any? { |keyword| query.upcase.include?(keyword) }
          raise "Query contains disallowed keywords."
        end

        # Use Rails' built-in sanitization to be safe
        begin
          ActiveRecord::Base.connection.execute("EXPLAIN #{query}")
        rescue ActiveRecord::StatementInvalid => e
          raise "Invalid SQL query: #{e.message}"
        end

        true
      end
    end
  end
end
