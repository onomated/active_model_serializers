class AuthorSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :posts, embed: :ids
  has_one :bio
end

class BlogSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class CommentSerializer < ActiveModel::Serializer
  attributes :id, :body

  belongs_to :post
  belongs_to :author
end

class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :body

  has_many :comments, serializer: CommentSerializer
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: AuthorSerializer

  def blog
    Blog.new(id: 999, name: 'Custom blog')
  end
end

class CachingAuthorSerializer < AuthorSerializer
  cache key: 'writer', skip_digest: true
end

class CachingCommentSerializer < CommentSerializer
  cache expires_in: 1.day, skip_digest: true
end

class CachingPostSerializer < PostSerializer
  cache key: 'post', expires_in: 0.1, skip_digest: true
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: CachingAuthorSerializer
  has_many :comments, serializer: CachingCommentSerializer
end

# ActiveModelSerializers::Model is a convenient
# serializable class to inherit from when making
# serializable non-activerecord objects.
class BenchmarkModel
  include ActiveModel::Model
  include ActiveModel::Serializers::JSON

  attr_reader :attributes

  def initialize(attributes = {})
    @attributes = attributes
    super
  end

  # Defaults to the downcased model name.
  def id
    attributes.fetch(:id) { self.class.name.downcase }
  end

  # Defaults to the downcased model name and updated_at
  def cache_key
    attributes.fetch(:cache_key) { "#{self.class.name.downcase}/#{id}-#{updated_at.strftime("%Y%m%d%H%M%S%9N")}" }
  end

  # Defaults to the time the serializer file was modified.
  def updated_at
    attributes.fetch(:updated_at) { File.mtime(__FILE__) }
  end

  def read_attribute_for_serialization(key)
    if key == :id || key == 'id'
      attributes.fetch(key) { id }
    else
      attributes[key]
    end
  end
end

class Comment < BenchmarkModel
  attr_accessor :id, :body

  def cache_key
    "#{self.class.name.downcase}/#{id}"
  end
end

class Author < BenchmarkModel
  attr_accessor :id, :name, :posts
end

class Post < BenchmarkModel
  attr_accessor :id, :title, :body, :comments, :blog, :author

  def cache_key
    'benchmarking::post/1-20151215212620000000000'
  end
end

class Blog < BenchmarkModel
  attr_accessor :id, :name
end
