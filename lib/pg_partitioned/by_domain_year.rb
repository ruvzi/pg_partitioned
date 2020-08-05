module PgPartitioned
  class ByDomainYear < List
    self.abstract_class = true

    partition_by :domain_year

    belongs_to :domain
    before_validation :add_domain_year!
    validates :domain_year, presence: true

    class << self
      def table_prefix(value)
        d, y = value.to_s.scan(/(\d+)(\d{4})/).first # [domain_id,year].join
        "y#{y}_#{d}"
      end

      def child_table_name_value(child_table_name)
        prefix = child_table_name.split('.', 2).last.sub(table_name, '').tr('_', '')
        prefix.to_s.scan(/y(\d{4})_(\d+)/).first.reverse.join # "y#{year}_#{domain_id}" -> [domain_id,year].join
      end

      def normalize_new_partition_value(domain_id)
        [domain_id, Date.today.year].join
      end
    end


    private

    def add_domain_year!
      self.domain_year ||= yearly_resource.domain_year
    end
  end
end