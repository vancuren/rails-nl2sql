module Rails
  module Nl2sql
    class SchemaBuilder
      def self.build_schema(options = {})
        tables = get_filtered_tables(options)
        
        schema_text = build_schema_text(tables)
        schema_text
      end

      def self.get_database_type
        adapter = ActiveRecord::Base.connection.adapter_name.downcase
        case adapter
        when 'postgresql'
          'PostgreSQL'
        when 'mysql', 'mysql2'
          'MySQL'
        when 'sqlite3'
          'SQLite'
        when 'oracle'
          'Oracle'
        when 'sqlserver'
          'SQL Server'
        else
          'PostgreSQL' # Default fallback
        end
      end

      def self.get_filtered_tables(options = {})
        all_tables = ActiveRecord::Base.connection.tables
        
        # Remove system tables
        all_tables.reject! { |table| system_table?(table) }
        
        # Apply filtering options
        if options[:exclude]
          all_tables -= options[:exclude]
        end
        
        if options[:include]
          all_tables = options[:include] & all_tables
        end
        
        all_tables
      end

      def self.build_schema_text(tables)
        schema_parts = []
        
        tables.each do |table|
          schema_parts << build_table_schema(table)
        end
        
        schema_parts.join("\n\n")
      end

      def self.build_table_schema(table)
        columns = ActiveRecord::Base.connection.columns(table)
        
        schema = "CREATE TABLE #{table} (\n"
        
        column_definitions = columns.map do |column|
          type_info = get_column_type_info(column)
          nullable = column.null ? "" : " NOT NULL"
          default = column.default ? " DEFAULT #{column.default}" : ""
          
          "  #{column.name} #{type_info}#{nullable}#{default}"
        end
        
        schema += column_definitions.join(",\n")
        schema += "\n);"
        
        # Add indexes and foreign keys if available
        indexes = get_table_indexes(table)
        if indexes.any?
          schema += "\n\n-- Indexes for #{table}:"
          indexes.each do |index|
            schema += "\n-- #{index[:type]}: #{index[:columns].join(', ')}"
          end
        end
        
        schema
      end

      def self.get_column_type_info(column)
        case column.type
        when :string
          "VARCHAR(#{column.limit || 255})"
        when :text
          "TEXT"
        when :integer
          "INTEGER"
        when :bigint
          "BIGINT"
        when :float
          "FLOAT"
        when :decimal
          precision = column.precision || 10
          scale = column.scale || 0
          "DECIMAL(#{precision},#{scale})"
        when :datetime
          "TIMESTAMP"
        when :date
          "DATE"
        when :time
          "TIME"
        when :boolean
          "BOOLEAN"
        when :json
          "JSON"
        else
          column.sql_type || "TEXT"
        end
      end

      def self.get_table_indexes(table)
        indexes = []
        
        begin
          connection = ActiveRecord::Base.connection
          if connection.respond_to?(:indexes)
            table_indexes = connection.indexes(table)
            table_indexes.each do |index|
              indexes << {
                type: index.unique? ? "UNIQUE INDEX" : "INDEX",
                columns: index.columns,
                name: index.name
              }
            end
          end
        rescue => e
          # Skip if indexes can't be retrieved
        end
        
        indexes
      end

      def self.system_table?(table)
        system_tables = [
          'schema_migrations',
          'ar_internal_metadata',
          'sqlite_sequence',
          'information_schema',
          'performance_schema',
          'mysql',
          'sys'
        ]
        
        system_tables.any? { |sys_table| table.include?(sys_table) }
      end

      # Legacy method for backward compatibility
      def self.build_hash_schema(options = {})
        tables = get_filtered_tables(options)
        
        schema = {}
        tables.each do |table|
          schema[table] = ActiveRecord::Base.connection.columns(table).map(&:name)
        end

        schema
      end
    end
  end
end
