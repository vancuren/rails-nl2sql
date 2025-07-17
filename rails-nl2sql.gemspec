
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails/nl2sql/version"

Gem::Specification.new do |spec|
  spec.name          = "rails-nl2sql"
  spec.version       = Rails::Nl2sql::VERSION
  spec.authors       = ["Russell Van Curen"]
  spec.email         = ["russell@vancuren.net"]

  spec.summary       = %q{A Ruby on Rails gem for converting natural language to SQL.}
  spec.description   = %q{This gem provides an easy way to integrate natural language to SQL functionality into your Ruby on Rails projects. It uses AI models to convert natural language queries into SQL statements.}
  spec.homepage      = "https://github.com/vancuren/rails-nl2sql"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/vancuren/rails-nl2sql"
    spec.metadata["changelog_uri"] = "https://github.com/vancuren/rails-nl2sql/blob/main/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "openai", "~> 0.3"
  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec-rails"
end
