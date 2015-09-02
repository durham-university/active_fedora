module ActiveFedora::PropertyFilters
  class RelevanceOrderFilter
    def self.init_property(name, properties)
      properties[:class_name] = 'ActiveFedora::PropertyFilters::ValueWithRelevance'
    end

    def self.set_value(value)
      return nil if value.nil?
      Array(value).each_with_index.map do |v,i|
        ValueWithRelevance.new.tap do |wrapper|
          wrapper.value = v
          wrapper.relevance = 1.0/(i+1)
        end
      end
    end

    def self.get_value(value,*args)
      (value.sort do |a,b| b.relevance <=> a.relevance end).map do |x| x.value.first end
    end
  end

  class ValueWithRelevance
    include ActiveTriples::RDFSource
    configure type: ::RDF::URI.new('http://changethis.org/value_with_relevance')
    property :value, predicate: ::RDF::URI.new('http://changethis.org/value')
    property :relevance, predicate: ::RDF::URI.new('http://changethis.org/relevance')
  end
end
