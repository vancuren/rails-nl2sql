require "rails/nl2sql"
require "rails"

module Rails
  module Nl2sql
    class Railtie < Rails::Railtie
      initializer "rails-nl2sql.configure_rails_initialization" do |app|
        app.config.after_initialize do
          # Nothing to do here for now
        end
      end
    end
  end
end