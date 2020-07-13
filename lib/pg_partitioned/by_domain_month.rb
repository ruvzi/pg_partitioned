module PgPartitioned
  class ByDomainYear < List
    self.abstract_class = true

    partition_by :domain_year

    def self.table_prefix(value)
      d, y, m = value.to_s.scan(/(\d+)(\d{4})(\d{2})/).first # [domain_id,year,month].join
      "#{y}_#{m}_#{d}"
    end
  end
end