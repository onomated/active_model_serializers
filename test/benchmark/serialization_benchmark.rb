require_relative 'benchmark_helper'

module ActionController
  module Serialization
    class SerializerTest < ActionController::TestCase
      class PostController < ActionController::Base
        def render_with_cache_enable
          comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
          author  = Author.new(id: 1, name: 'Joao Moura.')
          post    = Post.new(id: 1, title: 'New Post', blog: nil, body: 'Body', comments: [comment], author: author)

          render json: post, adapter: :json
        end

        def render_with_cache_disabled
          comment = Comment.new(id: 1, body: 'ZOMG A COMMENT')
          author  = Author.new(id: 1, name: 'Joao Moura.')
          post    = Post.new(id: 1, title: 'New Post', blog: nil, body: 'Body', comments: [comment], author: author)

          render json: post, serializer: CachingPostSerializer, adapter: :json
        end
      end

      tests PostController

      def test_render_benchmark
        if run_only?
          n_times.times do
            _test_render_cache_enabled
          end
          true
        end and return

        _test_render_cache_enabled
        ActionController::Base.cache_store.clear
        get :render_with_cache_disabled
        assert_expected


        n = times
        Benchmark.bmbm do |x|
          x.report('cache') do
            ActionController::Base.cache_store.clear
            i = 0
            while i < n
              get :render_with_cache_enable
              i += 1
            end
          end
          x.report('no cache') do
            ActionController::Base.cache_store.clear
            i = 0
            while i < n
              get :render_with_cache_disabled
              i += 1
            end
          end
        end
        assert_expected
      end

      private

      def run_only?
        ENV['RUN_ONCE'] == '0'
      end

      def n_times
        Integer(ENV.fetch('TIMES', 1_000))
      end

      def _test_render_cache_enabled
        ActionController::Base.cache_store.clear
        get :render_with_cache_enable
        assert_expected
      end

      def expected
        expected = expected = {
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
      end

      def assert_expected
        assert_equal 'application/json', @response.content_type
        assert_equal expected.to_json, @response.body
      end

    end
  end
end
