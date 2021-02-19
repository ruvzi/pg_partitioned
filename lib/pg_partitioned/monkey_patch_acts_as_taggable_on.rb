module ActsAsTaggableOn
  module Taggable
    def taggable_on(preserve_tag_order, *tag_types)
      tag_types = tag_types.to_a.flatten.compact.map(&:to_sym)

      if taggable?
        self.tag_types = (self.tag_types + tag_types).uniq
        self.preserve_tag_order = preserve_tag_order
      else
        class_attribute :tag_types
        self.tag_types = tag_types
        class_attribute :preserve_tag_order
        self.preserve_tag_order = preserve_tag_order

        class_eval do
          has_many :taggings, as: :taggable, dependent: :destroy, class_name: '::ActsAsTaggableOn::Tagging', partition_key: :domain_id
          has_many :base_tags, through: :taggings, source: :tag, class_name: '::ActsAsTaggableOn::Tag'

          def self.taggable?
            true
          end
        end
      end

      # each of these add context-specific methods and must be
      # called on each call of taggable_on
      include Core
      include Collection
      include Cache
      include Ownership
      include Related
    end
  end
end