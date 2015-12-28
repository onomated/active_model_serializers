require_relative 'benchmark_helper'
require 'benchmark/ips'
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

      def test_render_benchmark
        scenarios = {
          'caching on: caching serializers' => { cache_on: true, action: :render_with_caching_serializer },
          'caching off: caching serializers' => { cache_on: false, action: :render_with_caching_serializer },
          'caching on: non-caching serializers' => { cache_on: true, action: :render_with_non_caching_serializer },
          'caching off: non-caching serializers' => { cache_on: false, action: :render_with_non_caching_serializer }
        }
        json_path = ENV['OUTPUT_PATH']
        puts "Saving output to json_path '#{json_path}'"
        Benchmark.ips(quiet: true) do |x|
          # the warmup phase (default 2) and calculation phase (default 5)
          x.config(time: 5, warmup: 2)
          scenarios.each do |name, options|
            x.report(name) do |times|
              ActionController::Base.cache_store.clear
              action = options.fetch(:action)
              cache_on!(options.fetch(:cache_on))
              # get action
              # assert_equal 'application/json', @response.content_type
              # assert_equal expected.to_json, @response.body
              i = 0
              while i < times
                get options[:action]
                i += 1
              end
            end
          end

          x.json!(json_path) if json_path
          x.compare!
        end
      end

      private

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

      def cache_on!(bool)
        # Uncomment to debug
        # STDERR.puts @controller.cache_store.class
        # STDERR.puts @controller.view_cache_dependencies
        @controller.perform_caching = bool
      end
    end
  end
end
