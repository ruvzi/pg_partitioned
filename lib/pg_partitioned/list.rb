module PgPartitioned
  class List < Base
    self.abstract_class = true

    class << self
      def partition_by(key = nil, &block)
        PgPartitioned::Model::Injector.new(self, key || block).inject_list_methods
      end

      def table_prefix(value)
        value
      end

      def create_new_partition(value)
        partition_value = normalize_new_partition_value(value)
        new_partition_table = partition_table_name(partition_value)
        return if partitions.include?(new_partition_table)
        create_partition(values: [partition_value], name: new_partition_table)
      end

      def normalize_new_partition_value(value)
        value
      end
    end
  end
end
