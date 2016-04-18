module ActiveModel
  class Serializer
    class SerializableHash
      attr_reader :serializer

      def initialize(serializer)
        @serializer = serializer
      end

      def serializable_hash(options)
        cached_attributes(options[:fields], options[:adapter_instance])
          .merge(cached_relationships(options[:include], options[:adapter_instance]))
      end

      def cached_attributes(fields, adapter_instance)
        serializer.cache_check(adapter_instance) do
          serializer.attributes(fields)
        end
      end

      def cached_relationships(include_tree, adapter_instance)
        relationships = {}
        serializer.associations(include_tree).each do |association|
          relationships[association.key] ||= cached_relationship(association, include_tree, adapter_instance)
        end

        relationships
      end

      def cached_relationship(association, include_tree, adapter_instance)
        return association.options[:virtual_value] if association.options[:virtual_value]
        return nil unless association.serializer && association.serializer.object

        association_serializer = association.serializer
        association_options = { include: include_tree[association.key] }
        association_include_tree = build_include_tree(association_options[:include])
        association_options = association_options.reverse_merge(adapter_instance: adapter_instance, include: include_tree)

        if association_serializer.respond_to?(:each)
          adapter_cached_name = adapter_instance.respond_to?(:cached_name) ? adapter_instance.cached_name : adapter_instance
          association_options[:cached_attributes] ||= ActiveModel::Serializer.cache_read_multi(association_serializer, adapter_cached_name, association_include_tree)
          serialize_collection_serializer(association_serializer, association_options)
        else
          association_serializer.serializable_hash(association_options)
        end
      end

      def serialize_collection_serializer(collection_serializer, serialization_options)
        collection_serializer.map do |each_serializer|
          ActiveModel::Serializer::SerializableHash.new(each_serializer).serializable_hash(serialization_options)
        end
      end

      def serialize_serializer(serializer, serialization_options)
        ActiveModel::Serializer::SerializableHash.new(serializer).serializable_hash(serialization_options)
      end

      private

      def build_include_tree(includes)
        ActiveModel::Serializer::IncludeTree.from_include_args(includes || '*')
      end
    end
  end
end
