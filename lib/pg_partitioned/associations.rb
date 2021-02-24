module PgPartitioned

  # Adds partition_key to belongs_to , has_one and has_many
  module Associations
    module PartitionedBelongsTo
      def belongs_to(target, options = {})
        partition_key = options.delete(:partition_key)
        result = super(target, options)
        if partition_key
          result[target.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{target}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
              alias_method :#{target}_without_partitioned_unscoped, :#{target}
              alias_method :#{target}, ::#{target}_with_partitioned_unscoped

              def #{target}_with_partitioned_unscoped(*args)
                association = association(:#{target})
                owner_partition_key = association.owner.send(association.options[:partition_key])
                return #{target}_without_partitioned_unscoped(*args) if !association.klass.try(:partitioned?) || args.present? || owner_partition_key.blank?
                    
                association.klass.where(association.options[:partition_key] => owner_partition_key).scoping { #{target}_without_partitioned_unscoped(*args) }
              end
            RUBY
          end
        end

        result
      end
    end

    module PartitionedHasMany
      def has_many(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end
        partition_key = options.delete(:partition_key)
        result = super(name, scope, options, &extension)
        if partition_key
          result[name.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{name}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
              alias_method :#{name}_without_partitioned_unscoped, :#{name}
              alias_method :#{name}, ::#{name}_with_partitioned_unscoped

              def #{name}_with_partitioned_unscoped(*args)
                association = association(:#{name})
                owner_partition_key = association.owner.send(association.options[:partition_key])
                return #{name}_without_partitioned_unscoped(*args) if !association.klass.try(:partitioned?) || args.present? || owner_partition_key.blank?
                  
                #{name}_without_partitioned_unscoped(*args).where(association.options[:partition_key] => owner_partition_key)
              end
            RUBY
          end
        end

        result
      end
    end

    module PartitionedHasOne
      def has_one(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end
        partition_key = options.delete(:partition_key)
        result = super(name, scope, options, &extension)
        if partition_key
          result[name.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{name}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
              alias_method :#{name}_without_partitioned_unscoped, :#{name}
              alias_method :#{name}, ::#{name}_with_partitioned_unscoped
              def #{name}_with_partitioned_unscoped(*args)
                association = association(:#{name})
                owner_partition_key = association.owner.send(association.options[:partition_key])
                return #{name}_without_partitioned_unscoped(*args) if !association.klass.partitioned? || args.present? || owner_partition_key.blank?
                  
                association.klass.where(association.options[:partition_key] => owner_partition_key).scoping { #{name}_without_partitioned_unscoped(*args) }
              end
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

ActiveRecord::Base.prepend PgPartitioned::Associations::PartitionedBelongsTo
ActiveRecord::Base.prepend PgPartitioned::Associations::PartitionedHasMany
ActiveRecord::Base.prepend PgPartitioned::Associations::PartitionedHasOne
# ActiveRecord::Associations::Preloader::Association.send :include, PgPartitioned::PreloaderAssociation