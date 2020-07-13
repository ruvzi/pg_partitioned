# frozen_string_literal: true

module PgPartitioned
  module Model
    class Decorator < SimpleDelegator
      def partitions
        PgPartitioned.cache.fetch_partitions(cache_key) do
          connection.select_values(<<-SQL)
            SELECT pg_inherits.inhrelid::regclass::text
            FROM pg_tables
            INNER JOIN pg_inherits
              ON pg_tables.tablename::regclass = pg_inherits.inhparent::regclass
            WHERE pg_tables.tablename = #{connection.quote(table_name)}
          SQL
        end
      rescue
        []
      end

      def create_range_partition(start_range:, end_range:, **options)
        modified_options = options.merge(
          start_range: start_range,
          end_range: end_range,
          primary_key: primary_key)

        create_partition(:create_range_partition_of, table_name, **modified_options)
      end

      def create_list_partition(values:, **options)
        modified_options = options.merge(
          values: values,
          primary_key: primary_key)

        create_partition(:create_list_partition_of, table_name, **modified_options)
      end

      private

      def create_partition(migration_method, table_name, **options)
        transaction { connection.send(migration_method, table_name, **options) }
      end

      def cache_key
        __getobj__.object_id
      end
    end
  end
end
