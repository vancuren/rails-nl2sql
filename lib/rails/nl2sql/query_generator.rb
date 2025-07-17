require "openai"

module Rails
  module Nl2sql
    class QueryGenerator
      def initialize(api_key, model = "gpt-3.5-turbo-instruct")
        @client = OpenAI::Client.new(access_token: api_key)
        @model = model
      end

      def generate_query(prompt, schema, db_server = "PostgreSQL", tables = nil)
        retrieved_context = build_context(schema, tables)
        
        # Debug: Let's see what schema context is being sent
        puts "=== SCHEMA CONTEXT BEING SENT TO AI ==="
        puts retrieved_context
        puts "=== END SCHEMA CONTEXT ==="
        
        system_prompt = build_system_prompt(db_server, retrieved_context)
        user_prompt = build_user_prompt(prompt)
        
        full_prompt = "#{system_prompt}\n\n#{user_prompt}"

        response = @client.completions(
          parameters: {
            model: @model,
            prompt: full_prompt,
            max_tokens: 500,
            temperature: 0.1
          }
        )

        generated_query = response.dig("choices", 0, "text")&.strip
        
        # Clean up the response to remove markdown formatting
        generated_query = clean_sql_response(generated_query)
        
        # Safety check
        validate_query_safety(generated_query)
        
        generated_query
      end

      private

      def build_context(schema, tables)
        if tables&.any?
          # Filter schema to only include requested tables
          filtered_schema = filter_schema_by_tables(schema, tables)
          filtered_schema
        else
          schema
        end
      end

      def filter_schema_by_tables(schema, tables)
        # Simple filtering - in a real implementation, this would be more sophisticated
        lines = schema.split("\n")
        filtered_lines = []
        current_table = nil
        include_current = false
        
        lines.each do |line|
          if line.match(/CREATE TABLE (\w+)/)
            current_table = $1
            include_current = tables.include?(current_table)
          end
          
          if include_current || line.strip.empty?
            filtered_lines << line
          end
        end
        
        filtered_lines.join("\n")
      end

      def build_system_prompt(db_server, retrieved_context)
        <<~PROMPT
          You are an expert SQL assistant specializing in generating dynamic queries based on natural language.
          Your primary goal is to generate **correct, safe, and executable #{db_server} SQL queries** based on user questions.

          ---
          **DATABASE CONTEXT (SCHEMA):**
          You are provided with relevant schema details from the database, retrieved to help you.
          **STRICTLY adhere to this provided schema context.** Do not use any tables or columns not explicitly listed here.
          #{retrieved_context}

          ---
          **SQL GENERATION RULES:**
          1. **SQL Dialect:** All generated SQL must be valid **#{db_server} syntax**.
             * For limiting results, use LIMIT (e.g., LIMIT 10) instead of TOP.
             * Be mindful of #{db_server}'s specific function names (e.g., COUNT(*), MAX()) and behaviors.
             * For subqueries that return a single value to be used in a WHERE clause, ensure they are correctly formatted for #{db_server}.
          2. **Schema Adherence:** Only use table names and column names that are explicitly present in the provided context. Do not invent names.
          3. **Valid JOIN Paths:** All `JOIN` operations must be based on valid foreign key relationships. The provided schema context explicitly details many of these.
          4. **Safety First:** Absolutely **DO NOT** generate any DDL (CREATE, ALTER, DROP) or DML (INSERT, UPDATE, DELETE) statements. Only `SELECT` queries are permitted.
          5. **CRITICAL: Handling Missing/Empty Text Data:**
             * When a user asks about "missing," "no," "empty," or "null" values for a TEXT column (like 'email', 'phone', 'address', 'company', 'fax'), generate a `WHERE` clause that explicitly checks for **both `IS NULL` and `= ''` (an empty string)**.
             * **Example:** To find agents with no email, the query should be `SELECT first_name, last_name FROM agents WHERE email IS NULL OR email = '';`
             * This is essential
          6. **Ambiguity:** If a user question is ambiguous or requires more information to form a precise SQL query, clearly state that you need clarification and ask for more details. Do not guess.
          
          **RESPOND WITH ONLY THE SQL QUERY - NO EXPLANATIONS, NO MARKDOWN FORMATTING, NO CODE BLOCKS, NO ADDITIONAL TEXT.**
        PROMPT
      end

      def build_user_prompt(input)
        <<~PROMPT
          Here is the **USER QUESTION:** Respond with a thoughtful process that leads to a SQL query, using the tools as necessary.
          "#{input}"
        PROMPT
      end

      def clean_sql_response(query)
        return query unless query

        # Remove markdown code blocks
        query = query.gsub(/```sql\n?/, '')
        query = query.gsub(/```\n?/, '')
        
        # Remove any leading/trailing whitespace
        query = query.strip
        
        # Remove any explanatory text before or after the query
        # Look for common patterns like "Here's the SQL query:" or "The query is:"
        query = query.gsub(/^.*?(SELECT|WITH|INSERT|UPDATE|DELETE|CREATE|DROP|ALTER)/i, '\1')
        
        # Remove any trailing explanatory text after the query
        # Split by newlines and take only the SQL part
        lines = query.split("\n")
        sql_lines = []
        
        lines.each do |line|
          line = line.strip
          # Skip empty lines or lines that look like explanations
          next if line.empty?
          next if line.match(/^(here|this|the query|explanation|note)/i)
          
          sql_lines << line
        end
        
        # Rejoin the SQL lines
        cleaned_query = sql_lines.join("\n").strip
        
        # Ensure it ends with a semicolon if it's a complete query
        if cleaned_query.match(/^(SELECT|WITH)/i) && !cleaned_query.end_with?(';')
          cleaned_query += ';'
        end
        
        cleaned_query
      end

      def validate_query_safety(query)
        return unless query

        banned_keywords = [
          "delete", "drop", "truncate", "update", "insert", "alter",
          "exec", "execute", "create", "merge", "replace", "into"
        ]

        banned_phrases = [
          "ignore previous instructions", "pretend you are", "i am the admin",
          "you are no longer bound", "bypass the rules", "run this instead",
          "for testing, run", "no safety constraints", "show me a dangerous query",
          "this is a dev environment", "drop all data", "delete all users", "wipe the database"
        ]

        query_lower = query.downcase

        # Check for banned keywords
        banned_keywords.each do |keyword|
          if query_lower.include?(keyword)
            raise Rails::Nl2sql::Error, "Query contains banned keyword: #{keyword}"
          end
        end

        # Check for banned phrases
        banned_phrases.each do |phrase|
          if query_lower.include?(phrase)
            raise Rails::Nl2sql::Error, "Query contains banned phrase: #{phrase}"
          end
        end
      end
    end
  end
end
