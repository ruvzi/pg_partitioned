require "pg_partitioned/config"
require "pg_partitioned/cache"
require "pg_partitioned/monkey_patch_activerecord"
require "pg_partitioned/monkey_patch_awesome_nested_set"
require "pg_partitioned/associations"

module PgPartitioned
  @config = Config.new
  @cache = Cache.new

  class << self
    attr_reader :config, :cache

    def configure(&block)
      block.call(config)
    end

    def reset
      @config = Config.new
      @cache = Cache.new
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require "pg_partitioned/hacks/schema_cache"

  ActiveRecord::ConnectionAdapters::SchemaCache.include(
      PgPartitioned::Hacks::SchemaCache)


  require "active_record/tasks/postgresql_database_tasks"
  require "pg_partitioned/hacks/postgresql_database_tasks"

  ActiveRecord::Tasks::PostgreSQLDatabaseTasks.prepend(
      PgPartitioned::Hacks::PostgreSQLDatabaseTasks)

  begin
    require "active_record/connection_adapters/postgresql_adapter"
    require "pg_partitioned/adapter/postgresql_methods"

    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include(
        PgPartitioned::Adapter::PostgreSQLMethods)
  rescue LoadError
    # migration methods will not be available
  end
  require 'pg_partitioned/base'
  require 'pg_partitioned/list'
  require 'pg_partitioned/range'
  require 'pg_partitioned/by_domain_id'
  require 'pg_partitioned/by_domain_year'
  require 'pg_partitioned/by_campaign_id'
  require 'pg_partitioned/by_day_stamp'
end