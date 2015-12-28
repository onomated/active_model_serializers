# https://github.com/rails-api/active_model_serializers/pull/872
# approx ref 792fb8a9053f8db3c562dae4f40907a582dd1720 to test against
# require 'test_helper'
require 'bundler/setup'

require 'rails'
require 'active_model'
require 'active_support'
require 'active_support/json'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
abort "Rails application already defined: #{Rails.application.class}" if Rails.application
require 'minitest/autorun'
# Ensure backward compatibility with Minitest 4
Minitest::Test = MiniTest::Unit::TestCase unless defined?(Minitest::Test)

# ref: https://gist.github.com/bf4/8744473
class BenchmarkApp < Rails::Application
  config.action_controller.perform_caching = true
  ActionController::Base.cache_store       = :memory_store

  # Set up production configuration
  config.eager_load = true
  config.cache_classes = true

  config.active_support.test_order = :random
  config.secret_token = '1234'
  config.secret_key_base = 'abc123'
  config.logger = Logger.new(IO::NULL)
end

require 'active_model_serializers'

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

# Needs to initialize app before any serializes are defined, for sanity's sake.
# Otherwise, you have to manually set perform caching.
Rails.application.initialize!

require_relative 'fixtures'

# Uncomment the below to test that cache is in use.
# ActiveSupport::Cache::Store.logger = Logger.new(STDERR)
