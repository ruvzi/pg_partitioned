require 'paranoia'

module ParanoiaPartitioned
  private
  def paranoia_restore_attributes
    attrs = super
    attrs.merge!(attributes.symbolize_keys.slice(self.class.partition_key)) if self.class.respond_to?(:partition_key)
    attrs
  end

  def paranoia_destroy_attributes
    attrs = super
    attrs.merge!(attributes.symbolize_keys.slice(self.class.partition_key)) if self.class.respond_to?(:partition_key)
    attrs
  end
end

Paranoia.prepend ParanoiaPartitioned