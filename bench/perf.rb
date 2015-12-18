require "pathname"
ams_dir = Pathname File.expand_path(['..', '..'].join(File::Separator), __FILE__)
LIB_PATH = ams_dir.join("lib")
# Use absolute path so we can run benchmark in tempdir
$LOAD_PATH.unshift(LIB_PATH.to_s)
require 'bundler/setup'
Bundler.require
require 'rails'
raise 'Rails application already defined!' if Rails.application
# require 'action_controller'
# require 'action_controller/test_case'
# require 'action_controller/railtie'
# require 'active_support/json'
# # https://gist.github.com/bf4/8744473
#
#   require 'benchmark'
#   require 'pathname'
#   require 'active_support/all'
#   require 'rails/railtie'
#   require 'active_support/railtie'
#   require 'active_support/dependencies'
#   require_dependency 'active_record/railtie'
#   Object.send :include, ActiveSupport
#   root = Pathname File.expand_path('../../..', __FILE__)
#   ["app/**/", "lib/**/"].each do |glob|
#     Dir.glob(glob).each do |dir|
#       Dependencies.autoload_paths << root.join(dir)
#     end
#   end
# https://github.com/bf4/book_code/blob/master/railsnatra/code/1_config.ru
require "rails"
require "active_support/railtie"
require "action_controller/railtie"
class TestServer < Rails::Application
  # Set up production configuration
  config.eager_load = true
  config.cache_classes = true

  # A key base is required for our app to boot
  config.secret_key_base =
    routes.append {
      root to: proc {
        [200, {"Content-Type" => "text/html"}, []]
      }
      # Routes = ActionDispatch::Routing::RouteSet.new
      # Routes.draw do
      # controller = Class.new(ActionController::Base) do
      #   def self.call(env)
      #     action(:index
      #   end
      # end
      # get '/test', to: controller
      # get ':controller(/:action(/:id))'
      # get ':controller(/:action)'
      # end
  }.to_s
  # g `secret_token` and `secret_key_base` f

  # config.root = root
  # config.logger = Logger.new(nil)
  # config.active_support.deprecation = :log
  # config.active_support.test_order = :random


  config.action_controller.perform_caching = true
  ActionController::Base.cache_store = :memory_store
end
main = Process.pid
TestServer.initialize!
# server_thread = Thread.new do
  require "rack"
  # Rack::Server.start
  # run TestServer
  app = TestServer
  port = 9292
  # Rack::Handler::WEBrick.run(app, Port: port, AccessLog: [], Logger: WEBrick::Log::new(nil, 0))
  Rack::Server.start :app => app.new, :Port => port
# end
# Rails.applications.route_set.call(
# run Rails.application
@exit_status = nil
at_exit do
  # Store the exit status of the test run since it goes away after calling the at_exit proc...
  @exit_status = $!.status if $!.is_a?(SystemExit)
  if Process.pid == main
    puts 'I am you'
  else
    puts 'I am me'
  end
  exit @exit_status if @exit_status # Force exit with stored status
end
# run Rails.application
# run TheSmallestRailsApp ||= Class.new(Rails::Application) {
#   config.secret_key_base = routes.append {
#     root to: proc {
#       [200, {"Content-Type" => "text/html"}, [Markaby::Builder.new.html {
#         title @title = "The Smallest Rails App"
#         h3 "I am #@title!"
#         p "Here is my source code:"
#         text CodeRay.scan_file(__FILE__).div(line_numbers: :table)
#         p { a "Make me smaller", href: "//goo.gl/YdRpy" }
#       }]]
#     }
#   }.to_s
#   initialize!
# }
# db_config  = File.read(Rails.root.join('config/database.yml'))
#   db_config = ERB.new(db_config).result(binding)
#   db_settings = YAML::load(db_config)['test']
#   ActiveRecord::Base.establish_connection(db_settings)
#   Rails.logger = Logger.new(STDOUT)
#   # Tracking SQL queries
#   Rails.configuration.query_count = 0
#   ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, details|
#     if details[:sql] =~ /UPDATE/
#       # Rails.logger.info details
#       Rails.configuration.query_count += 1
#     end
#   end
#
#
# ActionController::Base.cache_store = :memory_store
# require 'active_model_serializers'
# ActiveModel::Serializer.config.cache_store ||= ActiveSupport::Cache.lookup_store(ActionController::Base.cache_store || Rails.cache || :memory_store)
#
# module Benchmarking
#   module RailsApp
#     class Application < Rails::Application
#       config.secret_token = routes.append {
#         root to: proc {
#           [200, {"Content-Type" => "text/html"}, []]
#         }
#       }.to_s
#       config.root = root
#       config.active_support.deprecation = :log
#       config.eager_load = false
#     end
#   end
#   class Model
#     include ActiveModel::Model
#     include ActiveModel::Serializers::JSON
#
#     attr_reader :attributes
#
#     def initialize(attributes = {})
#       @attributes = attributes
#       super
#     end
#
#     # Defaults to the downcased model name.
#     def id
#       attributes.fetch(:id) { self.class.name.downcase }
#     end
#
#     # Defaults to the downcased model name and updated_at
#     def cache_key
#       attributes.fetch(:cache_key) { "#{self.class.name.downcase}/#{id}-#{updated_at.strftime("%Y%m%d%H%M%S%9N")}" }
#     end
#
#     # Defaults to the time the serializer file was modified.
#     def updated_at
#       attributes.fetch(:updated_at) { File.mtime(__FILE__) }
#     end
#
#     def read_attribute_for_serialization(key)
#       if key == :id || key == 'id'
#         attributes.fetch(key) { id }
#       else
#         attributes[key]
#       end
#     end
#   end
#   class Comment < Model
#     attr_accessor :id, :body
#
#     def cache_key
#       "#{self.class.name.downcase}/#{self.id}"
#     end
#   end
#   class Author < Model
#     attr_accessor :id, :name
#   end
#   class Post < Model
#     attr_accessor :id, :title, :blog, :body, :comments, :author
#     def cache_key
#       "benchmarking::post/1-20151215212620000000000"
#     end
#   end
#   class Blog < Model
#     attr_accessor :id, :name
#   end
#   class PostSerializer < ActiveModel::Serializer
#     cache key: 'post', expires_in: 0.1, skip_digest: true
#     attributes :id, :title, :body
#
#     has_many :comments
#     belongs_to :blog
#     belongs_to :author
#
#     def blog
#       Blog.new(id: 999, name: 'Custom blog')
#     end
#   end
#   class CommentSerializer < ActiveModel::Serializer
#     cache expires_in: 1.day, skip_digest: true
#     attributes :id, :body
#
#     belongs_to :post
#     belongs_to :author
#   end
#   class AuthorSerializer < ActiveModel::Serializer
#     cache key: 'writer', skip_digest: true
#     attribute :id
#     attribute :name
#
#     has_many :posts
#   end
#   class BlogSerializer < ActiveModel::Serializer
#     cache key: 'blog'
#     attributes :id, :name
#   end
# end
#
#
# comment = Benchmarking::Comment.new({ id: 1, body: 'ZOMG A COMMENT' })
# author  = Benchmarking::Author.new(id: 1, name: 'Joao Moura.')
# post    = Benchmarking::Post.new({ id: 1, title: 'New Post', blog:nil, body: 'Body', comments: [comment], author: author })
# serializer = Benchmarking::PostSerializer.new(post)
# adapter = ActiveModel::Serializer::Adapter.create(serializer)
# serialization = adapter
# # serialization = ActiveModel::SerializableResource.new(post, serializer: Benchmarking::PostSerializer, adapter: :attributes)
# expected_attributes = {
#   id: 1,
#   title: 'New Post',
#   body: 'Body',
# }
# expected_associations = {
#   comments: [
#     {
#       id: 1,
#       body: 'ZOMG A COMMENT' }
#   ],
#   blog: {
#     id: 999,
#     name: 'Custom blog'
#   },
#   author: {
#     id: 1,
#     name: 'Joao Moura.'
#   }
# }
# expected = expected_attributes.merge(expected_associations)
# # p [serializer.attributes, expected_attributes].tap {|a| a.unshift(a[0] == a[1]) }
# # p [serializer.class._cache, ActionController::Base.cache_store].tap {|a| a.unshift(a[0] == a[1]) }
# # p [serializer.class._cache_options, {expires_in: 0.1, skip_digest: true }].tap {|a| a.unshift(a[0] == a[1]) }
# # p [serializer.class._cache_key, post.cache_key] #.tap {|a| a.unshift(a[0] == a[1]) }
# # p [serialization.serializable_hash, ActiveModel::Serializer.config.cache_store.fetch(post.cache_key)].tap {|a| a.unshift(a[0] == a[1]) }
# # # p [serializer.class._cache_digest, Digest::MD5.hexdigest(IO.read(__FILE__))].tap {|a| a.unshift(a[0] == a[1]) }
# # p [serializer.class._cache_only]
# # p [serializer.class._cache_except]
# # p [serialization.serializable_hash, expected].tap {|a| a.unshift(a[0] == a[1]) }
# define_method(:cache_on) do |caching_on|
#   ActiveModel::Serializer.config.cache_store.clear
#   ActiveModel::Serializer.config.perform_caching = caching_on
# end
# define_method(:run_example_code) do
#   attributes = serializer.attributes
#   attributes == expected_attributes or fail "#{attributes} isn't equal to #{expected}"
# # -> { attributes = serializer.attributes == expected
# end
# define_method(:after_run) do
#   # p ActiveModel::Serializer.config.cache_store
# end
# # require "benchmark/ips"
# # puts "Running Benchmark.ips"
# # n = 10_000
# # reports = Benchmark.bmbm do |x|
# # # reports = Benchmark.ips do |x|
# # #   # the warmup phase (default 2) and calculation phase (default 5)
# # #   x.config(time: 5, warmup: 2)
# #
# #   x.report("caching")  do |times|
# #     times ||= n
# #     Process.waitpid2(fork do
# #       cache_on(true)
# #       i = 0
# #       while i < times
# #         run_example_code
# #         i += 1
# #       end
# #     end)
# #     after_run
# #   end
# #
# #   x.report("no caching")  do |times|
# #     times ||= n
# #     Process.waitpid2(fork do
# #       cache_on(false)
# #       i = 0
# #       while i < times
# #         run_example_code
# #         i += 1
# #       end
# #     end)
# #     after_run
# #   end
# #
# #   # x.compare!
# # end
# def compare_result(expected, actual, tolerance = 0.13)
#   expected_result = parse_result(expected)
#   actual_result = parse_result(actual)
#   p [expected_result, actual_result]
#
#   # expected_result.each do |timing, value|
#   #   begin
#   #     # expect(actual_result[timing] / value).to be_within(tolerance).of(1.0)
#   #     p [timing, actual_result[timing] / value, tolerance]
#   #   rescue
#   #     STDOUT.puts "Timing: #{timing},  #{actual_result[timing] / value} should be within #{tolerance} of 1.0"
#   #     raise
#   #   end
#   # end
# end
# def bench!(strategy = ->{}, iters = 10_000)
#   strategy.call(10)
#   Benchmark.measure {
#     strategy.call(iters)
#   }
# end
# def parse_result(result)
#   if result.respond_to?(:utime)
#     user = result.utime
#     system = result.stime
#     total = result.total
#     real = result.real
#   else
#     user, system, total, real = result.strip.
#       gsub(/[^0-9\. ]/, '').
#       split(/\s+/).
#       map { |time| Float(time) }
#   end
#   {
#     :user => user,
#     :system => system,
#     :total => total,
#     :real => real,
#   }
# end
#
# STRATEGIES = {
#   'caching' => ->(times) do
#     Process.waitpid2(fork do
#       cache_on(true)
#       i = 0
#       while i < times
#         run_example_code
#         i += 1
#       end
#     end)
#     after_run
#   end,
#
#   'no caching' => ->(times)  do
#     Process.waitpid2(fork do
#       cache_on(false)
#       i = 0
#       while i < times
#         run_example_code
#         i += 1
#       end
#     end)
#     after_run
#   end
# }
# results = {
#   'caching'            => "1.480000   0.160000   1.640000 (  1.976294)", # 0 UPDATES
#   'no caching'          => "1.520000   0.150000   1.670000 (  2.014452)", # 0 UPDATES
# }.map { |test_name, _|
#   result = bench!(STRATEGIES.fetch(test_name))
#   puts "\tCurrent run result: #{result.to_s.strip}, -- #{test_name}"
#   result
# }
# compare_result(*results)
# # https://github.com/rails-api/active_model_serializers/pull/810#issuecomment-89870165
# # Update: here are the numbers I got:
# #
# #                user        system    total     real
# # no cache       21.550000   1.820000  23.370000 ( 28.894494)
# # cache          16.870000   1.580000  18.450000 ( 21.429540)
# # fragment cache 22.270000   1.810000  24.080000 ( 28.504920)
# #
# # (cache means `only: []` wasn't used in the serializer)
#
# # https://github.com/rails-api/active_model_serializers/pull/810#issuecomment-94940858
# #
# # # both fragment
# # cache only: [:field1, :field2, :etc]
# #
# # # and not fragment
# # cache
# #
# # # then, in an integration test:
# # Benchmark.bm do |x|
# #   x.report do
# #     1000.times do
# #       get "/users/#{user.id}", nil
# #     end
# #   end
# # end
# #
# #
# exit 0
