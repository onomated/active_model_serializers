require "pathname"
# ams_dir = Pathname File.expand_path(['..', '..'].join(File::Separator), __FILE__)
# LIB_PATH = ams_dir.join("lib")
# # Use absolute path so we can run benchmark in tempdir
# $LOAD_PATH.unshift(LIB_PATH.to_s)
# require 'bundler/setup'
require 'rails'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
require 'active_support/json'
ActionController::Base.cache_store = :memory_store
require 'active_model_serializers'
ActiveModel::Serializer.config.cache_store ||= ActiveSupport::Cache.lookup_store(ActionController::Base.cache_store || Rails.cache || :memory_store)
require 'benchmark/ips'

module Benchmarking
  class Comment < ActiveModelSerializers::Model
    attr_accessor :id, :body

    def cache_key
      "#{self.class.name.downcase}/#{self.id}"
    end
  end
  class Author < ActiveModelSerializers::Model
    attr_accessor :id, :name
  end
  class Post < ActiveModelSerializers::Model
    attr_accessor :id, :title, :blog, :body, :comments, :author
    def cache_key
      "benchmarking::post/1-20151215212620000000000"
    end
  end
  class Blog < ActiveModelSerializers::Model
    attr_accessor :id, :name
  end
  class PostSerializer < ActiveModel::Serializer
    cache key: 'post', expires_in: 0.1, skip_digest: true
    attributes :id, :title, :body

    has_many :comments
    belongs_to :blog
    belongs_to :author

    def blog
      Blog.new(id: 999, name: 'Custom blog')
    end
    class CommentSerializer < ActiveModel::Serializer
      cache expires_in: 1.day, skip_digest: true
      attributes :id, :body

      belongs_to :post
      belongs_to :author
    end
    class AuthorSerializer < ActiveModel::Serializer
      cache key: 'writer', skip_digest: true
      attribute :id
      attribute :name

      has_many :posts
    end
    class BlogSerializer < ActiveModel::Serializer
      cache key: 'blog'
      attributes :id, :name
    end
  end
end


comment = Benchmarking::Comment.new({ id: 1, body: 'ZOMG A COMMENT' })
author  = Benchmarking::Author.new(id: 1, name: 'Joao Moura.')
post    = Benchmarking::Post.new({ id: 1, title: 'New Post', blog:nil, body: 'Body', comments: [comment], author: author })
serializer = Benchmarking::PostSerializer.new(post)
serialization = ActiveModel::SerializableResource.new(post, serializer: Benchmarking::PostSerializer, adapter: :attributes)
expected_attributes = {
  id: 1,
  title: 'New Post',
  body: 'Body',
}
expected_associations = {
  comments: [
    {
      id: 1,
      body: 'ZOMG A COMMENT' }
  ],
  blog: {
    id: 999,
    name: 'Custom blog'
  },
  author: {
    id: 1,
    name: 'Joao Moura.'
  }
}
expected = expected_attributes.merge(expected_associations)
p [serializer.attributes, expected_attributes].tap {|a| a.unshift(a[0] == a[1]) }
p [serializer.class._cache, ActionController::Base.cache_store].tap {|a| a.unshift(a[0] == a[1]) }
p [serializer.class._cache_options, {expires_in: 0.1, skip_digest: true }].tap {|a| a.unshift(a[0] == a[1]) }
p [serializer.class._cache_key, post.cache_key] #.tap {|a| a.unshift(a[0] == a[1]) }
p [serialization.serializable_hash, ActiveModel::Serializer.config.cache_store.fetch(post.cache_key)].tap {|a| a.unshift(a[0] == a[1]) }
p [serializer.class._cache_digest, Digest::MD5.hexdigest(IO.read(__FILE__))].tap {|a| a.unshift(a[0] == a[1]) }
p [serializer.class._cache_only]
p [serializer.class._cache_except]
p [serialization.serializable_hash, expected].tap {|a| a.unshift(a[0] == a[1]) }
define_method(:cache_on) do |caching_on|
  ActiveModel::Serializer.config.cache_store.clear
  ActiveModel::Serializer.config.perform_caching = caching_on
end
define_method(:run_example_code) do
  attributes = serializer.attributes
  attributes == expected_attributes or fail "#{attributes} isn't equal to #{expected}"
# -> { attributes = serializer.attributes == expected
end
define_method(:after_run) do
  # p ActiveModel::Serializer.config.cache_store
end
require "benchmark/ips"
puts "Running Benchmark.ips"
reports = Benchmark.ips do |x|
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(time: 5, warmup: 2)

  x.report("caching")  do |times|
    Process.waitpid2(fork do
      cache_on(true)
      i = 0
      while i < times
        run_example_code
        i += 1
      end
    end)
    after_run
  end

  x.report("no caching")  do |times|
    Process.waitpid2(fork do
      cache_on(false)
      i = 0
      while i < times
        run_example_code
        i += 1
      end
    end)
    after_run
  end

  x.compare!
end
# https://github.com/rails-api/active_model_serializers/pull/810#issuecomment-89870165
# Update: here are the numbers I got:
#
#                user        system    total     real
# no cache       21.550000   1.820000  23.370000 ( 28.894494)
# cache          16.870000   1.580000  18.450000 ( 21.429540)
# fragment cache 22.270000   1.810000  24.080000 ( 28.504920)
#
# (cache means `only: []` wasn't used in the serializer)

# https://github.com/rails-api/active_model_serializers/pull/810#issuecomment-94940858
#
# # both fragment
# cache only: [:field1, :field2, :etc]
#
# # and not fragment
# cache
#
# # then, in an integration test:
# Benchmark.bm do |x|
#   x.report do
#     1000.times do
#       get "/users/#{user.id}", nil
#     end
#   end
# end
#
#
exit 0
