require 'erb'

module Rails
  module Nl2sql
    class PromptBuilder
      def self.build(input, db_server, retrieved_context)
        template = Rails::Nl2sql.prompt_template

        erb_context = Object.new
        erb_context.instance_variable_set(:@input, input)
        erb_context.instance_variable_set(:@db_server, db_server)
        erb_context.instance_variable_set(:@retrieved_context, retrieved_context)

        erb_context.define_singleton_method(:get_binding) do
          binding
        end

        erb_context.define_singleton_method(:input) { @input }
        erb_context.define_singleton_method(:db_server) { @db_server }
        erb_context.define_singleton_method(:retrieved_context) { @retrieved_context }

        system_prompt = ERB.new(template['system']).result(erb_context.get_binding)
        user_prompt = ERB.new(template['user']).result(erb_context.get_binding)

        "#{system_prompt}\n\n#{user_prompt}"
      end
    end
  end
end
