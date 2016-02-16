require 'bundler'
Bundler.setup

ENV.key?('PATH_TO_HIT') || ENV['PATH_TO_HIT'] = '/caching/on'
ENV.key?('TEST_COUNT') || ENV['TEST_COUNT'] = '10'
# USE_SERVER=webrick
# exec perf:mem
ENV['DERAILED_SKIP_ACTIVE_RECORD'] = 'true'
require 'derailed_benchmarks'
require 'derailed_benchmarks/tasks'

namespace :perf do
  Rake::Task['perf:rails_load'].clear
  task :rails_load do
    ENV['RAILS_ENV'] ||= 'production'
    ENV['RACK_ENV']  = ENV['RAILS_ENV']
    ENV['DISABLE_SPRING'] = 'true'

    ENV['SECRET_KEY_BASE'] ||= 'foofoofoo'

    ENV['LOG_LEVEL'] = 'FATAL'

    require 'rails'

    puts "Booting: #{Rails.env}"

    require_relative '../test/dummy/app'

    Rails.env = ENV['RAILS_ENV']

    DERAILED_APP = Rails.application

    if DERAILED_APP.respond_to?(:initialized?)
      DERAILED_APP.initialize! unless DERAILED_APP.initialized?
    else
      DERAILED_APP.initialize! unless DERAILED_APP.instance_variable_get(:@initialized)
    end

    # if  ENV["DERAILED_SKIP_ACTIVE_RECORD"] && defined? ActiveRecord
    #   if defined? ActiveRecord::Tasks::DatabaseTasks
    #     ActiveRecord::Tasks::DatabaseTasks.create_current
    #   else # Rails 3.2
    #     raise "No valid database for #{ENV['RAILS_ENV']}, please create one" unless ActiveRecord::Base.connection.active?.inspect
    #   end
    #
    #   ActiveRecord::Migrator.migrations_paths = DERAILED_APP.paths['db/migrate'].to_a
    #   ActiveRecord::Migration.verbose         = true
    #   ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths, nil)
    # end

    DERAILED_APP.config.consider_all_requests_local = true
  end
end
