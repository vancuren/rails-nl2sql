require 'active_support/concern'
require 'active_support/lazy_load_hooks'

module Rails
  module Nl2sql
    module ActiveRecordExtension
      extend ActiveSupport::Concern

      class_methods do
        def from_nl(prompt, options = {})
          sql = Rails::Nl2sql::Processor.generate_query_only(prompt, options)
          sql = sql.to_s.strip
          sql = sql.chomp(';')
          from(Arel.sql("(#{sql}) AS #{table_name}"))
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  include Rails::Nl2sql::ActiveRecordExtension
end
