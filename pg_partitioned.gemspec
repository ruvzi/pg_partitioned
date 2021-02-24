# coding: utf-8
# frozen_string_literal: true

# lib = File.expand_path("../lib", __FILE__)
# $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/pg_partitioned/version'

Gem::Specification.new do |spec|
  spec.name    = 'pg_partitioned'
  spec.version = PgPartitioned::VERSION
  spec.authors = ['Ruslan Zavatskyi']
  spec.email   = ['ruslan.zavatskyi@gmail.com']

  spec.summary     = %q{ActiveRecord PostgreSQL 11 Partitioning}
  spec.description = %q{Migrations and model helpers for creating and managing PostgreSQL 11 partitions}
  spec.homepage    = 'https://github.com/ruvzi/pg_partitioned'
  spec.license     = 'MIT'

  spec.files = Dir['LICENSE.txt', 'README.md', 'lib/**/*']

  spec.add_runtime_dependency 'activerecord', '~> 6.1.3'
  spec.add_runtime_dependency 'bulk_data_methods', '1.1.2'
  spec.add_runtime_dependency 'acts-as-taggable-on', '~> 7.0.0'
  spec.add_runtime_dependency 'acts_as_commentable_with_threading', '~> 2.0.1'
  spec.add_runtime_dependency 'awesome_nested_set', '~> 3.3.1'
  spec.add_runtime_dependency 'paranoia', '~> 2.4.3'

  spec.add_development_dependency 'appraisal', '~> 2.3.0'
  spec.add_development_dependency 'byebug', '~> 11.1.3'
  spec.add_development_dependency 'combustion', '~> 1.3.1'
  spec.add_development_dependency 'database_cleaner', '~> 2.0.1'
  spec.add_development_dependency 'nokogiri', '>= 1.11.1', '< 2.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.9.0'
  spec.add_development_dependency 'rake', '~> 13.0.1'
  spec.add_development_dependency 'rspec-its', '~> 1.3.0'
  spec.add_development_dependency 'rspec-rails', '~> 4.0.2'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.4.1'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'timecop', '~> 0.9.4'
end