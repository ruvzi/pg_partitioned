require 'awesome_nested_set'

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      module Model
        module ClassMethods
          def nested_set_scope(options = {})
            order = scope_order_from_options(options)
            conditions = options[:conditions]
            collection = try(:partitioned?) && conditions && conditions.keys.include?(partition_key) ?
                           from_partition_with_create(partition_key_value(conditions)) :
                           default_scoped
            collection.where(conditions).order(order)
          end
        end
      end

      def acts_as_nested_set_relate_parent!
        options = {
          :class_name => self.base_class.to_s,
          :foreign_key => parent_column_name,
          :primary_key => primary_column_name,
          :counter_cache => acts_as_nested_set_options[:counter_cache],
          :inverse_of => (:children unless acts_as_nested_set_options[:polymorphic]),
          :touch => acts_as_nested_set_options[:touch],
          :partition_key => acts_as_nested_set_options[:partition_key]
        }
        options[:polymorphic] = true if acts_as_nested_set_options[:polymorphic]
        options[:optional] = true if ActiveRecord::VERSION::MAJOR >= 5
        belongs_to :parent, **options
      end

      def acts_as_nested_set_relate_children!
        has_many_children_options = {
          :class_name => self.base_class.to_s,
          :foreign_key => parent_column_name,
          :primary_key => primary_column_name,
          :inverse_of => (:parent unless acts_as_nested_set_options[:polymorphic]),
          :partition_key => acts_as_nested_set_options[:partition_key]
        }
        # Add callbacks, if they were supplied.. otherwise, we don't want them.
        [:before_add, :after_add, :before_remove, :after_remove].each do |ar_callback|
          has_many_children_options.update(
              ar_callback => acts_as_nested_set_options[ar_callback]
          ) if acts_as_nested_set_options[ar_callback]
        end

        has_many :children, -> { order(order_column_name => :asc) },
                 **has_many_children_options
      end
    end
  end
end
