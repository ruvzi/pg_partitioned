require 'active_record'
require 'active_record/base'
require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/relation.rb'
require 'active_record/persistence.rb'
require 'active_record/relation/query_methods.rb'

#
# Patching {ActiveRecord} to allow specifying the table name as a function of
# attributes.
#
module ActiveRecord
  #
  # Patches for Persistence to allow certain partitioning (that related to the primary key) to work.
  #
  module Persistence
    # This method is patched to provide a relation referencing the partition instead
    # of the parent table.
    def relation_for_destroy
      pk         = self.class.primary_key
      column     = self.class.columns_hash[pk]
      substitute = self.class.connection.substitute_at(column)

      # ****** BEGIN PARTITIONED PATCH ******
      if self.class.respond_to?(:dynamic_arel_table)
        using_arel_table = dynamic_arel_table
        relation = ActiveRecord::Relation.new(self.class, using_arel_table).
            where(using_arel_table[pk].eq(substitute))
      else
        # ****** END PARTITIONED PATCH ******
        relation = self.class.unscoped.where(
            self.class.arel_table[pk].eq(substitute))
        # ****** BEGIN PARTITIONED PATCH ******
      end
      # ****** END PARTITIONED PATCH ******

      relation.bind_values = [[column, id]]
      relation
    end

    # This method is patched to prefetch the primary key (if necessary) and to ensure
    # that the partitioning attributes are always included (AR will exclude them
    # if the db column's default value is the same as the new record's value).
    def _create_record(attribute_names = self.attribute_names)
      if self.class.respond_to?(:partition_key)
        attribute_names.concat [self.class.partition_key.to_s]
        attribute_names.uniq!
      end
      attributes_values = arel_attributes_with_values_for_create(attribute_names)

      new_id = self.class.unscoped.insert attributes_values
      self.id ||= new_id if self.class.primary_key

      @new_record = false
      id
    end

    # Updates the associated record with values matching those of the instance attributes.
    # Returns the number of affected rows.
    def _update_record(attribute_names = @attributes.keys)
      # ****** BEGIN PARTITIONED PATCH ******
      # NOTE(hofer): This patch ensures the columns the table is
      # partitioned on are passed along to the update code so that the
      # update statement runs against a child partition, not the
      # parent table, to help with performance.
      if self.class.respond_to?(:partition_key)
        attribute_names.concat [self.class.partition_key.to_s]
        attribute_names.uniq!
      end
      # ****** END PARTITIONED PATCH ******
      attributes_values = arel_attributes_with_values_for_update(attribute_names)
      return 0 if attributes_values.empty?

      self.class.unscoped._update_record attributes_values, id, id_was
    end

  end # module Persistence

  module QueryMethods

    def build_arel
      if bind_values.present? && @klass.respond_to?(:dynamic_arel_table)
        actual_arel_table = @klass.dynamic_arel_table(Hash[*bind_values.map{ |c, v| [c.name, c.cast_type.type_cast_for_database(v)]}.flatten], @klass.table_name)
      end
      actual_arel_table ||= table
      arel = Arel::SelectManager.new(table.engine, actual_arel_table)

      build_joins(arel, joins_values.flatten) unless joins_values.empty?

      collapse_wheres(arel, (where_values - [''])) #TODO: Add uniq with real value comparison / ignore uniqs that have binds

      arel.having(*having_values.uniq.reject(&:blank?)) unless having_values.empty?

      arel.take(connection.sanitize_limit(limit_value)) if limit_value
      arel.skip(offset_value.to_i) if offset_value
      arel.group(*arel_columns(group_values.uniq.reject(&:blank?))) unless group_values.empty?

      build_order(arel)

      build_select(arel)

      arel.distinct(distinct_value)
      arel.from(build_from) if from_value
      arel.lock(lock_value) if lock_value

      arel
    end

    # def build_select(arel)
    #   if select_values.any?
    #     arel.project(*arel_columns(select_values.uniq))
    #   else
    #     Rails.logger.debug('build_select')
    #     Rails.logger.debug(@klass.arel_table[Arel.star])
    #     Rails.logger.debug(table[Arel.star])
    #     Rails.logger.debug('build_select end')
    #     # arel.project(table[Arel.star])
    #     arel.project(@klass.arel_table[Arel.star])
    #   end
    # end
  end # module QueryMethods

  class Relation

    # This method is patched to use a table name that is derived from
    # the attribute values.
    def insert(values) # :nodoc:
      primary_key_value = nil

      if primary_key && Hash === values
        primary_key_value = values[values.keys.find { |k|
          k.name == primary_key
        }]

        if !primary_key_value && connection.prefetch_primary_key?(klass.table_name)
          primary_key_value = connection.next_sequence_value(klass.sequence_name)
          values[klass.arel_table[klass.primary_key]] = primary_key_value
        end
      end

      im = arel.create_insert
      # ****** BEGIN PARTITIONED PATCH ******
      actual_arel_table = @klass.dynamic_arel_table(Hash[*values.map{|k,v| [k.name,v]}.flatten(1)]) if @klass.respond_to?(:dynamic_arel_table)
      actual_arel_table ||= @table
      # Original line:
      # im.into @table
      im.into actual_arel_table
      # ****** END PARTITIONED PATCH ******

      substitutes, binds = substitute_values values

      if values.empty? # empty insert
        im.values = Arel.sql(connection.empty_insert_statement_value)
      else
        im.insert substitutes
      end

      @klass.connection.insert(
          im,
          'SQL',
          primary_key,
          primary_key_value,
          nil,
          binds)
    end

    def _update_record(values, id, id_was) # :nodoc:
      substitutes, binds = substitute_values values

      scope = @klass.unscoped

      if @klass.finder_needs_type_condition?
        scope.unscope!(where: @klass.inheritance_column)
      end

      if @klass.respond_to?(:dynamic_arel_table)
        using_arel_table = @klass.dynamic_arel_table(Hash[*values.map { |k,v| [k.name,v] }.flatten(1)])
        relation = scope.where(using_arel_table[@klass.primary_key].eq(id_was || id))

        bvs = binds + relation.bind_values
        um = relation.arel.compile_update(substitutes, @klass.primary_key)
        begin
          @klass.arel_table.name = using_arel_table.name
          @klass.connection.update(um, 'SQL', bvs)
        ensure
          @klass.arel_table.name = @klass.table_name
        end
      else
        relation = scope.where(@klass.primary_key => (id_was || id))
        bvs = binds + relation.bind_values
        um = relation.arel.compile_update(substitutes, @klass.primary_key)

        @klass.connection.update(um, 'SQL', bvs)
      end
    end
  end # class Relation

  module Associations
    class Association
      def skip_statement_cache?
        reflection.scope_chain.any?(&:any?) ||
          scope.eager_loading? ||
          klass.current_scope ||
          klass.default_scopes.any? ||
          reflection.source_reflection.active_record.default_scopes.any? ||
          (klass.try(:partitioned?) && klass.partition_association?(reflection))
      end
    end
  end # class Associations
end # module ActiveRecord
