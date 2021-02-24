require 'active_record'
require 'active_record/base'
require 'active_record/connection_adapters/abstract_adapter'
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

    module ClassMethods
      def _insert_record(values)
        primary_key = self.primary_key
        primary_key_value = nil

        if primary_key && Hash === values
          primary_key_value = values[primary_key]

          if !primary_key_value && prefetch_primary_key?
            primary_key_value = next_sequence_value
            values[primary_key] = primary_key_value
          end
        end

        if values.empty?
          im = arel_table.compile_insert(connection.empty_insert_statement_value(primary_key))
          im.into arel_table
        else
          im = arel_table.compile_insert(_substitute_values(values))
          if respond_to?(:dynamic_arel_table)
            actual_arel_table = dynamic_arel_table(values) || arel_table
            im.into actual_arel_table
          end
        end

        connection.insert(im, "#{self} Create", primary_key || false, primary_key_value)
      end

      def _update_record(values, constraints)
        constraints = _substitute_values(constraints).map { |attr, bind| attr.eq(bind) }

        if respond_to?(:dynamic_arel_table)
          using_arel_table = dynamic_arel_table(values)
          using_arel_table ||= arel_table
          arel_table.name = using_arel_table.name
        end

        um = arel_table.where(
          constraints.reduce(&:and)
        ).compile_update(_substitute_values(values), primary_key)

        rs = connection.update(um, "#{self} Update")
        arel_table.name = table_name
        rs
      end
    end

    def _update_record(attribute_names = self.attribute_names)
      if self.class.respond_to?(:partition_key)
        attribute_names.concat [self.class.partition_key.to_s]
        attribute_names.uniq!
      end

      attribute_names = attributes_for_update(attribute_names)

      if attribute_names.empty?
        affected_rows = 0
        @_trigger_update_callback = true
      else
        affected_rows = _update_row(attribute_names)
        @_trigger_update_callback = affected_rows == 1
      end

      @previously_new_record = false

      yield(self) if block_given?

      affected_rows
    end

    def _create_record(attribute_names = self.attribute_names)
      if self.class.respond_to?(:partition_key)
        attribute_names.concat [self.class.partition_key.to_s]
        attribute_names.uniq!
      end

      attribute_names = attributes_for_create(attribute_names)

      new_id = self.class.unscoped._insert_record(
        attributes_with_values(attribute_names)
      )
      self.id ||= new_id if @primary_key

      @new_record = false
      @previously_new_record = true

      yield(self) if block_given?
      id
    end
  end # module Persistence

  module QueryMethods

    def build_arel(aliases)
      if where_clause.present? && @klass.respond_to?(:dynamic_arel_table)
        actual_arel_table = @klass.dynamic_arel_table(where_clause.to_h, @klass.table_name)
      end
      actual_arel_table ||= table
      arel = Arel::SelectManager.new(actual_arel_table)

      build_joins(arel.join_sources, aliases)

      arel.where(where_clause.ast) unless where_clause.empty?
      arel.having(having_clause.ast) unless having_clause.empty?
      arel.take(build_cast_value("LIMIT", connection.sanitize_limit(limit_value))) if limit_value
      arel.skip(build_cast_value("OFFSET", offset_value.to_i)) if offset_value
      arel.group(*arel_columns(group_values.uniq)) unless group_values.empty?

      build_order(arel)
      build_select(arel)

      arel.optimizer_hints(*optimizer_hints_values) unless optimizer_hints_values.empty?
      arel.distinct(distinct_value)
      arel.from(build_from) unless from_clause.empty?
      arel.lock(lock_value) if lock_value

      unless annotate_values.empty?
        annotates = annotate_values
        annotates = annotates.uniq if annotates.size > 1
        unless annotates == annotate_values
          ActiveSupport::Deprecation.warn(<<-MSG.squish)
              Duplicated query annotations are no longer shown in queries in Rails 6.2.
              To migrate to Rails 6.2's behavior, use `uniq!(:annotate)` to deduplicate query annotations
              (`#{klass.name&.tableize || klass.table_name}.uniq!(:annotate)`).
          MSG
          annotates = annotate_values
        end
        arel.comment(*annotates)
      end

      arel
    end
  end # module QueryMethods
end # module ActiveRecord
