module PgPartitioned
  class ByDayStamp < List
    self.abstract_class = true

    partition_by :day_stamp
    validates :day_stamp, presence: true

    class << self
      def table_prefix(value)
        value.to_s.scan(/(\d{2})(\d{2})(\d{4})/).first.join('_') # '%d%m%Y' -> %d_%m_%Y
      end

      def child_table_name_value(child_table_name)
        child_table_name.split('.', 2).last.sub(table_name, '').tr('_', '') # %d_%m_%Y -> '%d%m%Y'
      end
    end
  end
end