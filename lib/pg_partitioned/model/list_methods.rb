# frozen_string_literal: true

require "pg_partitioned/model/decorator"

module PgPartitioned
  module Model
    module ListMethods
      def create_partition(*args)
        PgPartitioned::Model::Decorator.new(self).create_list_partition(*args)
      end
    end
  end
end
