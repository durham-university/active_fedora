module ActiveFedora::Attributes
  class NodeConfig < ActiveTriples::NodeConfig
    def multiple?
      @multiple
    end

    def property_filter
      @property_filter
    end

    def initialize(term, predicate, options={})
      super
      @multiple = options[:multiple]
      @property_filter = options[:property_filter]
    end

  end
end
