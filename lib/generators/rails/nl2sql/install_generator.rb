require 'rails/generators'

class Rails::Nl2sql::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  def copy_initializer
    template 'rails_nl2sql.rb', 'config/initializers/rails_nl2sql.rb'
  end
end