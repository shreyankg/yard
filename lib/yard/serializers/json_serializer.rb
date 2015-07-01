require 'json'

module YARD
  module Serializers
    class JSONSerializer < FileSystemSerializer
      def initialize(jfile)
        super(:basepath => jfile)
      end

      def checksums_path; File.join(basepath, 'checksums') end
      def proxy_types_path; File.join(basepath, 'proxy_types.json') end
      def object_types_path; File.join(basepath, 'object_types.json') end

      def serialized_path(object)
        'objects.json'
      end

      def serialize(object)
        super(object, dump(object))
      end

      private

      # takes a code object and returns it's essential data structure
      def hasher(object)
        keys = %w'name signature namespace base_docstring files
            type source source_type dynamic group visibility'
        keys.zip(keys.map { |e| object[e] }).to_h
      end

      # structures object into data strutures
      def structured(object)
        struct = {}
        object.each do |k,v|
          struct[k] = hasher v
        end
        struct
      end

      # Dumps to JSON
      def dump(object)
        structured(object).to_json
      end

    end
  end
end
