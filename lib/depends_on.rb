require 'active_support'

module DependsOn
  extend ActiveSupport::Concern

  module ClassMethods
    def depends_on(*args)
      dependencies = args.map!(&:to_s)
      ancestors = self.ancestors.to_a.map(&:name)
      missing = dependencies - ancestors
      raise MissingDependencies.new(self, missing) if missing.length > 0
    end
  end

  class MissingDependencies < StandardError
    def initialize(obj, missing)

      msg = "#{obj.class} #{obj.name} must inherit from the following classes and/or modules: #{missing.join(', ')}"
      super(msg)
    end
  end
end