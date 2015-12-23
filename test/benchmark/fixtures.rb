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

  def custom_options
    options
  end
end

class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :body

  has_many :comments, serializer: CommentSerializer
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: AuthorSerializer

  def blog
    Blog.new(id: 999, name: 'Custom blog')
  end

  def custom_options
    options
  end
end

class CachingAuthorSerializer < AuthorSerializer
  cache key: 'writer'
end

class CachingCommentSerializer < CommentSerializer
  cache expires_in: 1.day
end

class CachingPostSerializer < PostSerializer
  cache key: 'post', expires_in: 0.1
  belongs_to :blog, serializer: BlogSerializer
  belongs_to :author, serializer: CachingAuthorSerializer
  has_many :comments, serializer: CachingCommentSerializer
end

class Model
  def initialize(hash = {})
    @attributes = hash
  end

  def cache_key
    "#{self.class.name.downcase}/#{id}-#{updated_at}"
  end

  def updated_at
    @attributes[:updated_at] ||= Time.current.to_i
  end

  def read_attribute_for_serialization(name)
    if name == :id || name == 'id'
      id
    else
      @attributes[name]
    end
  end

  def id
    @attributes[:id] || @attributes['id'] || object_id
  end

  def to_param
    id
  end

  def method_missing(meth, *args)
    if meth.to_s =~ /^(.*)=$/
      @attributes[Regexp.last_match(1).to_sym] = args[0]
    elsif @attributes.key?(meth)
      @attributes[meth]
    else
      super
    end
  end
end
class Comment < Model; end
class Author < Model; end
class Post < Model; end
class Blog < Model; end
