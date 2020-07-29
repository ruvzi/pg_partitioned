module PgPartitioned
  class ByCampaignId < List
    self.abstract_class = true

    partition_by :campaign_id
    validates :campaign_id, presence: true
  end
end