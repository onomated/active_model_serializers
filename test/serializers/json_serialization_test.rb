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

# serializable_hash
# Valid options are :only, :except, :methods and :include. The following are all valid examples:
#
# person.serializable_hash(only: 'name')
# person.serializable_hash(include: :address)
# person.serializable_hash(include: { address: { only: 'city' }})
# def serializable_hash(options = nil)
#   options ||= {}
#
#   attribute_names = attributes.keys
#   if only = options[:only]
#     attribute_names &= Array(only).map(&:to_s)
#   elsif except = options[:except]
#     attribute_names -= Array(except).map(&:to_s)
#   end
#
#   hash = {}
#   attribute_names.each { |n| hash[n] = read_attribute_for_serialization(n) }
#
#   Array(options[:methods]).each { |m| hash[m.to_s] = send(m) if respond_to?(m) }
#
#   serializable_add_includes(options) do |association, records, opts|
#     hash[association.to_s] = if records.respond_to?(:to_ary)
#       records.to_ary.map { |a| a.serializable_hash(opts) }
#     else
#       records.serializable_hash(opts)
#     end
#   end
#
#   hash
# end

# def as_json(options = nil)
#   root = if options && options.key?(:root)
#     options[:root]
#   else
#     include_root_in_json
#   end
#
#   if root
#     root = model_name.element if root == true
#     { root => serializable_hash(options) }
#   else
#     serializable_hash(options)
#   end
# end
# The :only and :except options can be used to limit the attributes included, and work similar to the attributes method.
#
# user.as_json(only: [:id, :name])
# # => { "id" => 1, "name" => "Konata Izumi" }
#
# user.as_json(except: [:id, :created_at, :age])
# # => { "name" => "Konata Izumi", "awesome" => true }
# To include the result of some method calls on the model use :methods:
#
# user.as_json(methods: :permalink)
# # => { "id" => 1, "name" => "Konata Izumi", "age" => 16,
# #      "created_at" => "2006/08/01", "awesome" => true,
# #      "permalink" => "1-konata-izumi" }
# To include associations use :include:
#
# user.as_json(include: :posts)
# # => { "id" => 1, "name" => "Konata Izumi", "age" => 16,
# #      "created_at" => "2006/08/01", "awesome" => true,
# #      "posts" => [ { "id" => 1, "author_id" => 1, "title" => "Welcome to the weblog" },
# #                   { "id" => 2, "author_id" => 1, "title" => "So I was thinking" } ] }
# Second level and higher order associations work as well:
#
# user.as_json(include: { posts: {
#                            include: { comments: {
#                                           only: :body } },
#                            only: :title } })
# # => { "id" => 1, "name" => "Konata Izumi", "age" => 16,
# #      "created_at" => "2006/08/01", "awesome" => true,
# #      "posts" => [ { "comments" => [ { "body" => "1st post!" }, { "body" => "Second!" } ],
# #                     "title" => "Welcome to the weblog" },
# #                   { "comments" => [ { "body" => "Don't think too hard" } ],
# #                     "title" => "So I was thinking" } ] }

    # def test_from_json
    #
    #   person= { name: 'bob', age: 22, awesome:true }.to_json
    #   person = Person.new
    #   person.from_json(json) # => #<Person:0x007fec5e7a0088 @age=22, @awesome=true, @name="bob">
    #   The default value for include_root is false. You can change it to true if the given JSON string includes a single root node.
    #
    #   json = { person: { name: 'bob', age: 22, awesome:true } }.to_json
    # end
  end
end
    # class AttributeTest < Minitest::Test
    #   def setup
    #     @blog = Blog.new({ id: 1, name: 'AMS Hints', type: 'stuff' })
    #     @blog_serializer = AlternateBlogSerializer.new(@blog)
    #   end
    #
    #   def test_attributes_definition
    #     assert_equal([:id, :title],
    #       @blog_serializer.class._attributes)
    #   end
    #
    #   def test_json_serializable_hash
    #     adapter = ActiveModel::Serializer::Adapter::Json.new(@blog_serializer)
    #     assert_equal({ blog: { id: 1, title: 'AMS Hints' } }, adapter.serializable_hash)
    #   end
    #
    #   def test_attribute_inheritance_with_key
    #     inherited_klass = Class.new(AlternateBlogSerializer)
    #     blog_serializer = inherited_klass.new(@blog)
    #     adapter = ActiveModel::Serializer::Adapter::Attributes.new(blog_serializer)
    #     assert_equal({ :id => 1, :title => 'AMS Hints' }, adapter.serializable_hash)
    #   end
    #
    #   def test_multiple_calls_with_the_same_attribute
    #     serializer_class = Class.new(ActiveModel::Serializer) do
    #       attribute :title
    #       attribute :title
    #     end
    #
    #     assert_equal([:title], serializer_class._attributes)
    #   end
    #
    #   def test_id_attribute_override
    #     serializer = Class.new(ActiveModel::Serializer) do
    #       attribute :name, key: :id
    #     end
    #
    #     adapter = ActiveModel::Serializer::Adapter::Json.new(serializer.new(@blog))
    #     assert_equal({ blog: { id: 'AMS Hints' } }, adapter.serializable_hash)
    #   end
    #
    #   def test_object_attribute_override
    #     serializer = Class.new(ActiveModel::Serializer) do
    #       attribute :name, key: :object
    #     end
    #
    #     adapter = ActiveModel::Serializer::Adapter::Json.new(serializer.new(@blog))
    #     assert_equal({ blog: { object: 'AMS Hints' } }, adapter.serializable_hash)
    #   end
    #
    #   def test_type_attribute
    #     attribute_serializer = Class.new(ActiveModel::Serializer) do
    #       attribute :id, key: :type
    #     end
    #     attributes_serializer = Class.new(ActiveModel::Serializer) do
    #       attributes :type
    #     end
    #
    #     adapter = ActiveModel::Serializer::Adapter::Json.new(attribute_serializer.new(@blog))
    #     assert_equal({ blog: { type: 1 } }, adapter.serializable_hash)
    #
    #     adapter = ActiveModel::Serializer::Adapter::Json.new(attributes_serializer.new(@blog))
    #     assert_equal({ blog: { type: 'stuff' } }, adapter.serializable_hash)
    #   end
    #
    #   def test_id_attribute_override_before
    #     serializer = Class.new(ActiveModel::Serializer) do
    #       def id
    #         'custom'
    #       end
    #
    #       attribute :id
    #     end
    #
    #     hash = ActiveModel::SerializableResource.new(@blog, adapter: :json, serializer: serializer).serializable_hash
    #
    #     assert_equal('custom', hash[:blog][:id])
    #   end
    #
    #   PostWithVirtualAttribute = Class.new(::Model)
    #   class PostWithVirtualAttributeSerializer < ActiveModel::Serializer
    #     attribute :name do
    #       "#{object.first_name} #{object.last_name}"
    #     end
    #   end
    #
    #   def test_virtual_attribute_block
    #     post = PostWithVirtualAttribute.new(first_name: 'Lucas', last_name: 'Hosseini')
    #     hash = serializable(post).serializable_hash
    #     expected = { name: 'Lucas Hosseini' }
    #
    #     assert_equal(expected, hash)
    #   end
    # end
# require 'test_helper'
#
# module ActiveModel
#   class Serializer
#     class AttributesTest < Minitest::Test
#       def setup
#         @profile = Profile.new({ name: 'Name 1', description: 'Description 1', comments: 'Comments 1' })
#         @profile_serializer = ProfileSerializer.new(@profile)
#         @comment = Comment.new(id: 1, body: 'ZOMG!!', date: '2015')
#         @serializer_klass = Class.new(CommentSerializer)
#         @serializer_klass_with_new_attributes = Class.new(CommentSerializer) do
#           attributes :date, :likes
#         end
#       end
#
#       def test_attributes_definition
#         assert_equal([:name, :description],
#           @profile_serializer.class._attributes)
#       end
#
#       def test_attributes_inheritance_definition
#         assert_equal([:id, :body], @serializer_klass._attributes)
#       end
#
#       def test_attributes_inheritance
#         serializer = @serializer_klass.new(@comment)
#         assert_equal({ id: 1, body: 'ZOMG!!' },
#           serializer.attributes)
#       end
#
#       def test_attribute_inheritance_with_new_attribute_definition
#         assert_equal([:id, :body, :date, :likes], @serializer_klass_with_new_attributes._attributes)
#         assert_equal([:id, :body], CommentSerializer._attributes)
#       end
#
#       def test_attribute_inheritance_with_new_attribute
#         serializer = @serializer_klass_with_new_attributes.new(@comment)
#         assert_equal({ id: 1, body: 'ZOMG!!', date: '2015', likes: nil },
#           serializer.attributes)
#       end
#
#       def test_multiple_calls_with_the_same_attribute
#         serializer_class = Class.new(ActiveModel::Serializer) do
#           attributes :id, :title
#           attributes :id, :title, :title, :body
#         end
#
#         assert_equal([:id, :title, :body], serializer_class._attributes)
#       end
#     end
#   end
# end
