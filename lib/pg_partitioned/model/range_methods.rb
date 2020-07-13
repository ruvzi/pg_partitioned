# frozen_string_literal: true

require "pg_partitioned/model/decorator"

module PgPartitioned
  module Model
    module RangeMethods
      def create_partition(*args)
        PgPartitioned::Model::Decorator.new(self).create_range_partition(*args)
      end
    end
  end
end
