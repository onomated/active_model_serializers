module ActiveModelSerializers
  module Adapter
    class Attributes < Base
      def initialize(serializer, options = {})
        super
        @include_tree = ActiveModel::Serializer::IncludeTree.from_include_args(options[:include] || '*')
      end

      def serializable_hash(options = nil)
        options = serialization_options(options)
        options.reverse_merge!(adapter_instance: self, include: @include_tree)

        if serializer.respond_to?(:each)
          serializer.map do |element|
            element.serialize(options, self, @include_tree)
          end
        else
          serializer.serialize(options, self, @include_tree)
        end
      end

      private

      # no-op: Attributes adapter does not include meta data, because it does not support root.
      def include_meta(json)
        json
      end
    end
  end
end
