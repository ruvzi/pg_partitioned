# frozen_string_literal: true

module PgPartitioned
  module Model
    class Injector
      def initialize(model, key)
        @model = model
        @key = key
      end

      def inject_range_methods
        require "pg_partitioned/model/range_methods"

        inject_methods_for(PgPartitioned::Model::RangeMethods)
      end

      def inject_list_methods
        require "pg_partitioned/model/list_methods"

        inject_methods_for(PgPartitioned::Model::ListMethods)
      end

      private

      def inject_methods_for(mod)
        require "pg_partitioned/model/base_methods"

        @model.extend(PgPartitioned::Model::BaseMethods)
        @model.extend(mod)

        @model.class_attribute(:partition_key, instance_accessor: false, instance_predicate: false)
        @model.partition_key = @key
      end
    end
  end
end
