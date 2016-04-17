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
          relationships[association.key] =
            if association.options[:virtual_value]
              association.options[:virtual_value]
            elsif association.serializer && association.serializer.object
              association_serializer = association.serializer
              association_options = { include: include_tree[association.key] }
              association_include_tree = ActiveModel::Serializer::IncludeTree.from_include_args(association_options[:include] || '*')
              association_options.reverse_merge!(adapter_instance: adapter_instance, include: include_tree)
              if association_serializer.respond_to?(:each)
                association_options[:cached_attributes] ||= ActiveModel::Serializer.cache_read_multi(association_serializer, adapter_instance, association_include_tree)
                association_serializer.map do |each_serializer|
                  each_serializer.serializable_hash(association_options)
                end
              else
                association_serializer.serializable_hash(association_options)
              end
            else
              nil
            end
        end

        relationships
      end
    end
  end
end
