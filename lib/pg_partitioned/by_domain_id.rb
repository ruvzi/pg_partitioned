module PgPartitioned
  class ByDomainId < List
    self.abstract_class = true

    partition_by :domain_id
    belongs_to :domain

  end
end