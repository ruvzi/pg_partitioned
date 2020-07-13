module PgPartitioned
  class ByDomainYear < List
    self.abstract_class = true

    partition_by :domain_year

    belongs_to :domain
    before_validation :add_domain_year!, on: :create
    validates :domain_year, presence: true

    scope :partitioned, -> (resource) { where(domain_year: resource.domain_year) }

    def self.table_prefix(value)
      d, y = value.to_s.scan(/(\d+)(\d{4})/).first # [domain_id,year].join
      "y#{y}_#{d}"
    end

    private

    def add_domain_year!
      self.domain_year = yearly_resource.domain_year
    end
  end
end