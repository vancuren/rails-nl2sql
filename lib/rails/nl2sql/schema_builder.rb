module Rails
  module Nl2sql
    class SchemaBuilder
      @@schema_cache = nil

      def self.build_schema(options = {})
        if options.empty? && @@schema_cache
          return @@schema_cache
        end

        tables = get_filtered_tables(options)

        schema_text = build_schema_text(tables)

        @@schema_cache = schema_text if options.empty?

        schema_text
      end

      def self.clear_cache!
        @@schema_cache = nil
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
        begin
          columns = ActiveRecord::Base.connection.columns(table)
        rescue => e
          # Skip tables that can't be introspected (e.g., PostGIS system tables)
          Rails.logger.debug "Skipping table #{table} due to introspection error: #{e.message}" if defined?(Rails)
          return "-- Table #{table} skipped due to introspection error"
        end
        
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
          # Handle PostGIS geometry types and other spatial types
          sql_type = column.sql_type || "TEXT"
          case sql_type.downcase
          when /geometry/
            "GEOMETRY"
          when /geography/
            "GEOGRAPHY"
          when /point/
            "POINT"
          when /polygon/
            "POLYGON"
          when /linestring/
            "LINESTRING"
          else
            sql_type
          end
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
        
        # PostGIS system tables
        postgis_system_tables = [
          'geometry_columns',
          'geography_columns',
          'spatial_ref_sys',
          'raster_columns',
          'raster_overviews',
          'topology',
          'layer',
          'topology_layer'
        ]
        
        # PostgreSQL system schemas
        pg_system_schemas = [
          'pg_',
          'information_schema'
        ]
        
        # Check regular system tables
        return true if system_tables.any? { |sys_table| table.include?(sys_table) }
        
        # Check PostGIS system tables
        return true if postgis_system_tables.any? { |sys_table| table == sys_table }
        
        # Check PostgreSQL system schemas
        return true if pg_system_schemas.any? { |schema| table.start_with?(schema) }
        
        false
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
