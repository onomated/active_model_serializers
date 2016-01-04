require 'test_helper'

class ActiveModel::Serializer
  class JsonSerializationTest < ActiveSupport::TestCase
    class Blog < ActiveModelSerializers::Model
      attr_accessor :id, :name, :authors
    end
    class Author < ActiveModelSerializers::Model
      attr_accessor :id, :name
    end
    class BlogSerializer < ActiveModel::Serializer
      attributes :id
      attribute :name, key: :title

      has_many :authors
    end
    class AuthorSerializer < ActiveModel::Serializer
      attributes :id, :name
    end

    setup do
      @authors = [ Author.new(id: 1, name: 'Blog Author') ]
      @blog = Blog.new({ id: 2, name: 'The Blog', authors: @authors})
      @serializer = BlogSerializer.new(@blog)
    end

    def test_serializer_to_json
      expected = { id: 2, title: 'The Blog' }
      expected_json = '{"id":2}'
      assert_equal(expected, @serializer.serializable_hash)
      assert_equal(expected, @serializer.as_json)
      assert_equal(expected_json, @serializer.to_json)
      assert_equal(expected, @serializer.as_json(methods: [:authors]))
    end
  end
end
