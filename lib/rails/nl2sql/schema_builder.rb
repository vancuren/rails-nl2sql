module Rails
  module Nl2sql
    class SchemaBuilder
      def self.build_schema(options = {})
        tables = ActiveRecord::Base.connection.tables
        tables -= options[:exclude] if options[:exclude]
        tables = options[:include] if options[:include]

        schema = {}
        tables.each do |table|
          schema[table] = ActiveRecord::Base.connection.columns(table).map(&:name)
        end

        schema
      end
    end
  end
end
