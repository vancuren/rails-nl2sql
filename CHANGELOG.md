# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.4] - 2025-07-18
### Fixed
- Fixed undefined variable error in ERB template processing

## [0.2.3] - 2025-07-18
### Added
- Pluggable LLM provider system with support for OpenAI, Anthropic, and Llama
- Custom prompt templates via ERB
- Context window management with configurable schema line limits
- Comprehensive error handling and validation

### Enhanced
- Improved security with query validation and banned keywords
- Better schema caching for performance
- Support for multiple database types (PostgreSQL, MySQL, SQLite, etc.)

## [0.2.0] - 2025-07-17
### Added
- ActiveRecord integration with `from_nl` method
- Schema caching for improved performance
- Multiple provider support (OpenAI, Anthropic, Llama)
- Configurable prompt templates
- Enhanced query validation and security

### Changed
- Improved architecture with provider abstraction
- Better error handling and user feedback
- More robust SQL generation and validation

## [0.1.0] - 2025-07-17
### Added
- Initial release
- Basic natural language to SQL conversion
- OpenAI integration
- Rails generator for easy setup
- Query validation and security features
- Support for table inclusion/exclusion
- Basic schema introspection