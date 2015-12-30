module ActiveModel
  class Serializer
    module Adapter
      class JsonApi
        class Link
          def initialize(serializer)
            @object = serializer.object
            @scope = serializer.scope
          end

          def href(value)
            self._href = value
            nil
          end

          def meta(value)
            self._meta = value
            nil
          end

          def value(value)
            if value.respond_to?(:call)
              string instance_eval(&value)
              _string || to_hash
            else
              value
            end
          end

          protected

          attr_accessor :_href, :_meta, :_string
          attr_reader :object, :scope

          private

          def to_hash
            hash = { href: _href }
            hash.merge!(meta: _meta) if _meta

            hash
          end

          def string(value)
            self._string = value
          end
        end
      end
    end
  end
end
