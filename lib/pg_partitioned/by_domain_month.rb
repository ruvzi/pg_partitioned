module PgPartitioned
  class ByDomainMonth < List
    self.abstract_class = true

    partition_by :domain_month

    class << self
      def table_prefix(value)
        d, y, m = value.to_s.scan(/(\d+)(\d{4})(\d{2})/).first # [domain_id,year,month].join
        "y#{y}_m#{m}_#{d}"
      end

      def child_table_name_value(child_table_name)
        prefix = child_table_name.split('.', 2).last.sub(table_name, '').tr('_', '')
        y, m, d = prefix.to_s.scan(/y(\d{4})_m(\d{2})_(\d+)/).first
        [d, y, m].join # "y#{year}_m#{month}_#{domain_id}" -> [domain_id,year,month].join
      end

      def normalize_new_partition_value(domain_id)
        [domain_id, Date.today.year, Date.today.month].join
      end
    end
  end
end