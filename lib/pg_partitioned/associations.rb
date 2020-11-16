module PgPartitioned

  # Adds partition_key to belongs_to
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :belongs_to, :partitioned
      end
    end

    module ClassMethods
      def belongs_to_with_partitioned(target, options = {})
        partition_key = options.delete(:partition_key)
        result = belongs_to_without_partitioned(target, options)

        if partition_key
          result[target.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{target}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
                def #{target}_with_partitioned_unscoped(*args)
                  association = association(:#{target})
                  return #{target}_without_partitioned_unscoped(*args) unless association.klass.partitioned? || args.present?
                  association.klass.from_partition_with_create(association.owner.send(association.options[:partition_key])).find_by(id: association.owner.send(association.reflection.foreign_key))
                end
                alias_method_chain :#{target}, :partitioned_unscoped
            RUBY
          end
        end

        result
      end
    end
  end

  # Loads associations correct with includes
  # module PreloaderAssociation
  #   def self.included(base)
  #     base.class_eval do
  #       def build_scope_with_partitioned
  #         scope = build_scope_without_partitioned
  #         binding.pry
  #         return scope if !klass.partitioned? || (partition_key = options[:partition_key]).blank?
  #         binding.pry
  #         scope
  #       end
  #
  #       alias_method_chain :build_scope, :partitioned
  #     end
  #   end
  # end
end

ActiveRecord::Base.send :include, PgPartitioned::Associations
# ActiveRecord::Associations::Preloader::Association.send :include, PgPartitioned::PreloaderAssociation