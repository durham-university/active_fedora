require 'active_fedora/digital_object'
require 'active_fedora/unsaved_digital_object'

module ActiveFedora

  module InMemory
    class << self
      attr_writer :object_cache
      def object_cache
        @object_cache ||= {}
      end

      def begin!
        cleanup!
        ActiveFedora.digital_object_class = ActiveFedora::InMemory::DigitalObject
        ActiveFedora.unsaved_digital_object_class = ActiveFedora::InMemory::UnsavedDigitalObject
      end

      def end!
        cleanup!
        ActiveFedora.digital_object_class = ActiveFedora::DigitalObject
        ActiveFedora.unsaved_digital_object_class = ActiveFedora::UnsavedDigitalObject
      end

      def cleanup!
        solr = ActiveFedora::SolrService.instance.conn
        solr = ActiveFedora::SolrService.instance.conn
        solr.delete_by_query("*:*", params: {commit: true})
        solr.commit
        @object_cache = {}
      end
    end
  class UnsavedDigitalObject < ActiveFedora::UnsavedDigitalObject
  end
  class DigitalObject < ActiveFedora::DigitalObject
    module PersistedObject
      def new?
        false
      end

      def createdDate
        @createdDate ||= [Time.now]
      end

      def lastModifiedDate
        [Time.now]
      end
    end

    def self.find_or_initialize(original_class, pid)
      connection = original_class.connection_for_pid(pid)
      obj = new(pid, connection)
      ActiveFedora::InMemory.object_cache.fetch(pid, obj)
    end

    def self.find(original_class, pid)
      raise ActiveFedora::ObjectNotFoundError.new("Unable to find #{pid.inspect} in fedora. ") unless pid.present?
      obj = begin
        ActiveFedora::InMemory.object_cache.fetch(pid)
      rescue KeyError
        raise ActiveFedora::ObjectNotFoundError, "Unable to find '#{pid}' in fedora. See logger for details."
      end

      obj.original_class = original_class
      obj.extend(PersistedObject)

      # PID is not found, but was "well-formed" for its Fedora request. So
      # an object is instantiated with that PID.
      raise ActiveFedora::ObjectNotFoundError, "Unable to find '#{pid}' in fedora" if obj.new?
      obj
    end

    def save
      self.extend(PersistedObject)
      ActiveFedora::InMemory.object_cache[pid] = self
      true
    end

    def delete
      ActiveFedora::InMemory.object_cache[pid] = nil
      solr = ActiveFedora::SolrService.instance.conn
      solr.delete_by_id(pid)
      solr.commit
      true
    end
  end
end
end