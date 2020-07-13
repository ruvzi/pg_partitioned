module PgPartitioned
  class Range < Base
    self.abstract_class = true

    def self.partition_by(key = nil, &block)
      PgPartitioned::Model::Injector.new(self, key || block).inject_range_methods
    end
  end
end