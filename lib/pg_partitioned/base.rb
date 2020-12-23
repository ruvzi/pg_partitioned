require "bulk_data_methods"

require "pg_partitioned/active_record_overrides"
require "pg_partitioned/model/injector"


module PgPartitioned
  class MethodNotImplemented < StandardError
    def initialize(model, method_name, is_class_method = true)
      super("#{model.name}#{is_class_method ? '.' : '#'}#{method_name}")
    end
  end

  class Base < ActiveRecord::Base
    include ActiveRecordOverrides
    extend ::BulkMethodsMixin

    self.abstract_class = true

    class << self
      def partition_key_value(values)
        values.symbolize_keys!
        values[partition_key]
      end

      def arel_table_from_key_value(partition_key_value, as = nil) #+
        @arel_tables ||= {}
        new_arel_table = @arel_tables[[partition_key_value, as]]

        unless new_arel_table
          arel_engine_hash = { engine: self.arel_engine, as: as}
          partition_table_name = self.partition_table_name(partition_key_value)
          create_new_partition(partition_key_value) unless partitions.include?(partition_table_name)
          new_arel_table = Arel::Table.new(partition_table_name, arel_engine_hash)
          @arel_tables[[partition_key_value, as]] = new_arel_table
        end

        new_arel_table
      end

      def dynamic_arel_table(values, as = nil)
        return if (key_value = self.partition_key_value(values)).blank?
        arel_table_from_key_value(key_value, as)
      end

      def from_partition(partition_key_value)
        table_alias_name = partition_table_alias_name(partition_key_value)
        ActiveRecord::Relation.new(self, self.arel_table_from_key_value(partition_key_value, table_alias_name))
      end

      def from_partition_with_create(partition_key_value)
        partition_table_name = partition_table_name(partition_key_value)
        unless partitions.include?(partition_table_name)
          PgPartitioned.cache.clear!
          create_new_partition(partition_key_value)
          PgPartitioned.cache.clear!
        end
        from_partition(partition_key_value)
      end

      def in_partition(child_table_name)
        from_partition(child_table_name_value(child_table_name))
      end

      def from_partition_without_alias(partition_key_value)
        ActiveRecord::Relation.new(self, self.arel_table_from_key_value(partition_key_value, nil))
      end
    end

    def partition_table_name
      self.class.partition_table_name(attributes.symbolize_keys[self.class.partition_key])
    end

    def dynamic_arel_table(as = nil)
      key_value = self.class.partition_key_value(attributes)
      self.class.arel_table_from_key_value(key_value, as)
    end
  end
end
