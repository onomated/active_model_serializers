# https://github.com/rails-api/active_model_serializers/pull/872
# approx ref 792fb8a9053f8db3c562dae4f40907a582dd1720 to test against
# require 'test_helper'
require 'minitest/autorun'

require 'rails'
require 'active_model'
require 'active_support'
require 'active_support/json'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
fail 'Cannot run when Rails.application is already defined' if Rails.application
ActionController::Base.cache_store = :memory_store
require 'active_model_serializers'
module Benchmarking
  module RailsApp
    class Application < Rails::Application
      # config.secret_token = routes.append {
      #   root to: proc {
      #     [200, {"Content-Type" => "text/html"}, []]
      #   }
      # }.to_s
      config.secret_token = '1234'
      config.secret_key_base = '4568'
      config.action_controller.perform_caching = ENV['DISABLE_CACHE'] != '1'
      ActionController::Base.cache_store = :memory_store
      # config.root = root
      # config.active_support.deprecation = :log
      config.eager_load = true
    end
  end
  class Model
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
  class Comment < Model
    attr_accessor :id, :body

    def cache_key
      "#{self.class.name.downcase}/#{self.id}"
    end
  end
  class Author < Model
    attr_accessor :id, :name
  end
  class Post < Model
    attr_accessor :id, :title, :blog, :body, :comments, :author
    def cache_key
      "benchmarking::post/1-20151215212620000000000"
    end
  end
  class Blog < Model
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

module TestHelper
  Routes = ActionDispatch::Routing::RouteSet.new
  Routes.draw do
    get ':controller(/:action(/:id))'
    get ':controller(/:action)'
  end

  ActionController::Base.send :include, Routes.url_helpers
end
ActionController::TestCase.class_eval do
  def setup
    @routes = TestHelper::Routes
  end
end
Rails.application.initialize!
ActiveModel::Serializer.config.cache_store ||= ActiveSupport::Cache.lookup_store(ActionController::Base.cache_store || Rails.cache || :memory_store)

module ActionController
  module Serialization
    class SerializerTest < ActionController::TestCase
      class PostController < ActionController::Base

        def render_with_cache_enable
          comment = Benchmarking::Comment.new({ id: 1, body: 'ZOMG A COMMENT' })
          author  = Benchmarking::Author.new(id: 1, name: 'Joao Moura.')
          post    = Benchmarking::Post.new({ id: 1, title: 'New Post', blog:nil, body: 'Body', comments: [comment], author: author })

          render json: post
        end
      end

      tests PostController

      def test_render_with_cache_enable
        times = Integer(ENV['TIMES'] || 2)
        puts "Caching is #{Rails.application.config.action_controller.perform_caching}. Running #{times} times"
        ActionController::Base.cache_store.clear
        i = 0
        while i < times
          print '.'
          get :render_with_cache_enable

          expected = {
            id: 1,
            title: 'New Post',
            body: 'Body',
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

          assert_equal 'application/json', @response.content_type
          assert_equal expected.to_json, @response.body

          get :render_with_cache_enable
          assert_equal expected.to_json, @response.body
          i += 1
        end
      end
    end
  end
end
