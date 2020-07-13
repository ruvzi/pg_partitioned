# frozen_string_literal: true

require "thread"

module PgPartitioned
  class Cache
    LOCK = Mutex.new

    def initialize
      @store = Hash.new { |h, k| h[k] = { partitions: nil } }
    end

    def clear!
      LOCK.synchronize { @store.clear }
      nil
    end


    def fetch_partitions(key, &block)
      return block.call unless caching_enabled?

      LOCK.synchronize { fetch_value(@store[key], :partitions, block) }
    end

    private

    def caching_enabled?
      PgPartitioned.config.caching
    end

    def fetch_value(subhash, key, block)
      entry = subhash[key]

      if entry.nil? || entry.expired?
        entry = Entry.new(block.call)
        subhash[key] = entry
      end

      entry.value
    end

    class Entry
      attr_reader :value

      def initialize(value)
        @value = value
        @timestamp = Time.now
      end

      def expired?
        ttl.positive? && Time.now - @timestamp > ttl
      end

      private

      def ttl
        PgPartitioned.config.caching_ttl
      end
    end

    private_constant :Entry
  end
end
