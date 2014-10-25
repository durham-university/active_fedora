module ActiveFedora
  module Versionable
    extend ActiveSupport::Concern

    included do
      class_attribute :versionable
    end

    module ClassMethods
      def has_many_versions
        self.versionable = true
      end
    end

    def model_type
      versionable_resource.query(subject: versionable_uri, predicate: RDF.type).objects
    end

    def versions
      results = versions_graph.query([versionable_uri, RDF::URI.new('http://fedora.info/definitions/v4/repository#hasVersion'), nil])
      results.map(&:object)
    end

    def create_version
      resp = ActiveFedora.fedora.connection.post(versions_url)
      @versions_graph = nil
      reload
      resp.success?
    end

    def restore_version uuid
      resp = ActiveFedora.fedora.connection.patch(version_url(uuid), nil)
      @versions_graph = nil
      reload
      refresh_attributes if self.respond_to?("refresh_attributes")
      resp.success?
    end

    def save(*)
      if kind_of? Datastream
        super.tap do |val|
          assert_versionable if versionable && val
        end
      else
        assert_versionable if versionable
        super
      end
    end

    private

      # RdfDatastream has a rdf_subject/resource that would take precidence over this one.
      # for a datastream we want the ContainerResource. For an Object just the regular resource
      def versionable_uri
        if kind_of? Datastream
          RDF::URI.new(uri)
        else
          versionable_resource.rdf_subject
        end
      end

      def versionable_resource
        if kind_of? Datastream
          metadata_resource.graph
        else
          resource
        end
      end

      def versions_graph
        @versions_graph ||= RDF::Graph.new << RDF::Reader.for(:ttl).new(versions_request)
      end

      def versions_request
        resp = begin
          ActiveFedora.fedora.connection.get(versions_url)
        rescue Ldp::NotFound
          return ''
        end
        if !resp.success?
          raise "unexpected return value #{resp.status} for when getting datastream content at #{uri}\n\t#{resp.body}"
        elsif resp.headers['content-type'] != 'text/turtle'
          raise "unknown response format. got '#{resp.headers['content-type']}', but was expecting 'text/turtle'"
        end
        resp.body
      end

      def versions_url
        uri + '/fcr:versions'
      end

      def version_url uuid
        versions_url + '/' + uuid
      end

      def assert_versionable
        if kind_of? Datastream
          stmt = "insert data { <#{versionable_uri}> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://www.jcp.org/jcr/mix/1.0versionable> . }"
          ActiveFedora.fedora.connection.patch(uri + '/fcr:metadata', stmt)
        else
          versionable_resource.insert(subject: versionable_uri, predicate: RDF.type, object: RDF::URI.new('http://www.jcp.org/jcr/mix/1.0versionable'))
        end
      end

  end
end