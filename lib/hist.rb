require "hist/engine"

module Hist
  # Your code goes here...

  def self.model(obj:nil,klass:nil)
    unless obj.nil?
      return obj.class.base_class.name
    end
    return klass.base_class.name
  end

  def self.config
    @config ||= Hist::Config.instance
    yield @config if block_given?
    @config
  end

end
