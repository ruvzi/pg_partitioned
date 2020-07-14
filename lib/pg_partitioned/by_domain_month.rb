module PgPartitioned
  class ByDomainMonth < List
    self.abstract_class = true

    partition_by :domain_month

    class << self
      def table_prefix(value)
        d, y, m = value.to_s.scan(/(\d+)(\d{4})(\d{2})/).first # [domain_id,year,month].join
        "y#{y}_m#{m}_#{d}"
      end

      def normalize_new_partition_value(domain_id)
        [domain_id, Date.today.year, Date.today.month].join
      end
    end
  end
end