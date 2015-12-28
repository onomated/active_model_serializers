require_relative 'benchmark_helper'
module ActionController
  module Serialization
    class SerializerTest < ActionController::TestCase
      class PostController < ActionController::Base
        POST =
          begin
            comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
            author  = Author.new(id: 1, name: 'Joao Moura.')
            Post.new(id: 1, title: 'New Post', blog: nil, body: 'Body', comments: [comment], author: author)
          end

        def render_with_caching_serializer
          render json: POST, adapter: :json
        end

        def render_with_non_caching_serializer
          render json: POST, serializer: CachingPostSerializer, adapter: :json
        end
      end

      tests PostController

      # External configuration:
      # Cache is on when CACHE_ON != 'false'
      # Tests CACHING_SERIALIZER != 'false' ? :render_with_caching_serializer : :render_with_non_caching_serializer
      # Iterates TIMES, defaults to 1,000
      def test_render_benchmark
        cache_on!(caching?)
        action = action_to_test
        warmup(action)
        if ENV['DEBUG'] == 'true'
          $stderr.puts "Running with caching '#{caching?}', against '#{action}', '#{n_times}' times."
        end
        request_loop(action, n_times)
      end

      private

      def request_loop(action, times)
        ActionController::Base.cache_store.clear
        i = 0
        while i < times
          get action
          i += 1
        end
      end

      def warmup(action)
        ActionController::Base.cache_store.clear
        get action
        assert_equal 'application/json', @response.content_type
        assert_equal expected.to_json, @response.body
      end

      def expected
        {
          post: {
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
        }
      end

      # Number of times to iterate, is 1,000, but can be set as TIMES=times
      def n_times
        Integer(ENV.fetch('TIMES', 1_000))
      end

      # Cache always on unless CACHE_ON=false
      def caching?
        ENV['CACHE_ON'] != 'false'
      end

      # Always test :render_with_caching_serializer
      # unless CACHING_SERIALIZER=false, then :render_with_non_caching_serializer
      def action_to_test
        if ENV['CACHING_SERIALIZER'] != 'false'
          :render_with_caching_serializer
        else
          :render_with_non_caching_serializer
        end
      end

      def cache_on!(bool)
        # Uncomment to debug
        # STDERR.puts @controller.cache_store.class
        # STDERR.puts @controller.view_cache_dependencies
        @controller.perform_caching = bool
      end
    end
  end
end
