module PgPartitioned
  class List < Base
    self.abstract_class = true

    def self.partition_by(key = nil, &block)
      PgPartitioned::Model::Injector.new(self, key || block).inject_list_methods
    end

    def self.table_prefix(value)
      value
    end
  end
end
