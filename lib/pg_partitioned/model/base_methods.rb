# frozen_string_literal: true

require "pg_partitioned/model/decorator"

module PgPartitioned
  module Model
    module BaseMethods
      def reset_primary_key
        if self != base_class
          base_class.primary_key
        elsif (partition_name = partitions.first).present?
          in_partition(partition_name).get_primary_key(base_class.name)
        else
          get_primary_key(base_class.name)
        end
      end

      def partitioned?
        partition_key.present?
      end

      def with_partition_schema?
        false
      end

      def partition_table_name(partition_key_value)
        [partition_schema_name, "#{table_name}_#{table_prefix(partition_key_value)}"].compact.join('.')
      end

      def partition_table_alias_name(partition_key_value)
        table_name.gsub(/[^a-zA-Z0-9]/, '_')
      end

      def partition_name(partition_key_value)
        partition_table_name(partition_key_value)
      end

      def child_table_name_value(child_table_name)
        child_table_name.split('.', 2).last.sub(table_name, '').sub(/^_/, '')
      end

      def partition_schema_name
        "#{table_name}_partitions" if with_partition_schema?
      end

      def table_exists?
        target_table = partitions.first || table_name
        connection.schema_cache.data_source_exists?(target_table)
      end

      def partitions
        PgPartitioned::Model::Decorator.new(self).partitions
      end
    end
  end
end
