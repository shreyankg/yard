require 'json'

module YARD
  module Serializers
    class JSONSerializer < FileSystemSerializer
      def initialize(jfile)
        super(:basepath => jfile, :extension => 'json')
      end

      def objects_path; File.join(basepath, 'objects') end
      def checksums_path; File.join(basepath, 'checksums') end
      def proxy_types_path; File.join(basepath, 'proxy_types') end
      def object_types_path; File.join(basepath, 'object_types') end

      def serialized_path(object)
        path = case object
        when String, Symbol
          object = object.to_s
          if object =~ /#/
            object += '_i'
          elsif object =~ /\./
            object += '_c'
          end
          object.split(/::|\.|#/).map do |p|
            p.gsub(/[^\w\.-]/) do |x|
              encoded = '_'

              x.each_byte { |b| encoded << ("%X" % b) }
              encoded
            end
          end.join('/') + '.' + extension
        when YARD::CodeObjects::RootObject
          'root.dat'
        else
          super(object)
        end
        File.join('objects', path)
      end

      def serialize(object)
        if Hash === object
          super(object[:root], dump(object)) if object[:root]
        else
          super(object, dump(object))
        end
      end

      private

      def dump(object)
        object = internal_dump(object, true) unless object.is_a?(Hash)
        JSON.dump(object)
      end

      def internal_dump(object, first_object = false)
        if !first_object && object.is_a?(CodeObjects::Base) &&
            !(Tags::OverloadTag === object)
          return StubProxy.new(object.path)
        end

        if object.is_a?(Hash) || object.is_a?(Array) ||
            object.is_a?(CodeObjects::Base) ||
            object.instance_variables.size > 0
          object = object.dup
        end

        object.instance_variables.each do |ivar|
          ivar_obj = object.instance_variable_get(ivar)
          ivar_obj_dump = internal_dump(ivar_obj)
          object.instance_variable_set(ivar, ivar_obj_dump)
        end

        case object
        when Hash
          list = object.map do |k, v|
            [k, v].map {|item| internal_dump(item) }
          end
          object.replace(Hash[list])
        when Array
          list = object.map {|item| internal_dump(item) }
          object.replace(list)
        end

        object
      end
    end
  end
end
