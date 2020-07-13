# frozen_string_literal: true

require "pg_partitioned/adapter_decorator"

module PgPartitioned
  module Adapter
    module PostgreSQLMethods
      def create_range_partition(*args, &block)
        PgPartitioned::AdapterDecorator.new(self).create_range_partition(*args, &block)
      end

      def create_list_partition(*args, &block)
        PgPartitioned::AdapterDecorator.new(self).create_list_partition(*args, &block)
      end

      def create_range_partition_of(*args)
        PgPartitioned::AdapterDecorator.new(self).create_range_partition_of(*args)
      end

      def create_list_partition_of(*args)
        PgPartitioned::AdapterDecorator.new(self).create_list_partition_of(*args)
      end

      def create_table_like(*args)
        PgPartitioned::AdapterDecorator.new(self).create_table_like(*args)
      end

      def attach_range_partition(*args)
        PgPartitioned::AdapterDecorator.new(self).attach_range_partition(*args)
      end

      def attach_list_partition(*args)
        PgPartitioned::AdapterDecorator.new(self).attach_list_partition(*args)
      end

      def detach_partition(*args)
        PgPartitioned::AdapterDecorator.new(self).detach_partition(*args)
      end

      def create_partition_schema(*args)
        PgPartitioned::AdapterDecorator.new(self).create_partition_schema(*args)
      end

      def drop_partition_schema(*args)
        PgPartitioned::AdapterDecorator.new(self).drop_partition_schema(*args)
      end
    end
  end
end
