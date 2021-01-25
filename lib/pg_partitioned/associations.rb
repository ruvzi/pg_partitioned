module PgPartitioned

  # Adds partition_key to belongs_to , has_one and has_many
  module Associations
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :belongs_to, :partitioned
        alias_method_chain :has_many, :partitioned
        alias_method_chain :has_one, :partitioned
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
                  owner_partition_key = association.owner.send(association.options[:partition_key])
                  return #{target}_without_partitioned_unscoped(*args) if !association.klass.try(:partitioned?) || args.present? || owner_partition_key.blank?
                    
                  association.klass.where(association.options[:partition_key] => owner_partition_key).scoping { #{target}_without_partitioned_unscoped(*args) }
                end
                alias_method_chain :#{target}, :partitioned_unscoped
            RUBY
          end
        end

        result
      end

      def has_many_with_partitioned(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end
        partition_key = options.delete(:partition_key)
        result = has_many_without_partitioned(name, scope, options, &extension)
        if partition_key
          result[name.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{name}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
                def #{name}_with_partitioned_unscoped(*args)
                  association = association(:#{name})
                  owner_partition_key = association.owner.send(association.options[:partition_key])
                  return #{name}_without_partitioned_unscoped(*args) if !association.klass.try(:partitioned?) || args.present? || owner_partition_key.blank?
                  
                  #{name}_without_partitioned_unscoped(*args).where(association.options[:partition_key] => owner_partition_key)
                end
                alias_method_chain :#{name}, :partitioned_unscoped
            RUBY
          end
        end

        result
      end

      def has_one_with_partitioned(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope   = nil
        end
        partition_key = options.delete(:partition_key)
        result = has_one_without_partitioned(name, scope, options, &extension)
        if partition_key
          result[name.to_s].options[:partition_key] = partition_key
          unless method_defined? "#{name}_with_partitioned_unscoped"
            class_eval <<-RUBY, __FILE__, __LINE__
                def #{name}_with_partitioned_unscoped(*args)
                  association = association(:#{name})
                  owner_partition_key = association.owner.send(association.options[:partition_key])
                  return #{name}_without_partitioned_unscoped(*args) if !association.klass.partitioned? || args.present? || owner_partition_key.blank?
                    
                  association.klass.where(association.options[:partition_key] => owner_partition_key).scoping { #{name}_without_partitioned_unscoped(*args) }
                end
                alias_method_chain :#{name}, :partitioned_unscoped
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