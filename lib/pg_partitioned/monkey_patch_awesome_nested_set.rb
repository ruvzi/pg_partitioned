require 'awesome_nested_set'

module CollectiveIdea #:nodoc:
  module Acts #:nodoc:
    module NestedSet #:nodoc:
      module Model
        module ClassMethods
          def nested_set_scope(options = {})
            options = {:order => { order_column => :asc }}.merge(options)
            conditions = options[:conditions] || {}
            collection = try(:partitioned?) && conditions.keys.include?(partition_key) ?
                           from_partition(partition_key_value(conditions)) :
                           self
            collection.where(conditions).order(options.delete(:order))
          end
        end
      end
    end
  end
end
