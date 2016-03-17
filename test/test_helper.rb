require 'tempfile'
require 'fileutils'

@stderr_file = Tempfile.new('app.stderr')
@app_root ||= Dir.pwd
@output_dir = File.join(@app_root, 'tmp')
FileUtils.mkdir_p(@output_dir)
@ignore_dirs = [
  File.join(@app_root, '.bundle'),
  File.join(@app_root, 'bundle'),
  File.join(@app_root, 'vendor')
]
@output = STDOUT
$VERBOSE = true
$stderr.reopen(@stderr_file.path)
at_exit do
  @stderr_file.rewind
  lines = @stderr_file.read.split("\n")
  @stderr_file.close!
  $stderr.reopen(STDERR)

  app_warnings, other_warnings = lines.partition do |line|
    line.include?(@app_root) && @ignore_dirs.none? { |ignore_dir| line.include?(ignore_dir) }
  end
  @output.puts
  @output.puts
  @output.puts 'app warnings:'
  @output.puts app_warnings
  @output.puts
  @output.puts 'other warnings:'
  @output.puts other_warnings
  @output.puts
end
require 'bundler/setup'

begin
  require 'simplecov'
  # HACK: till https://github.com/colszowka/simplecov/pull/400 is merged and released.
  # Otherwise you may get:
  # simplecov-0.10.0/lib/simplecov/defaults.rb:50: warning: global variable `$ERROR_INFO' not initialized
  require 'support/simplecov'
  AppCoverage.start
rescue LoadError
  STDERR.puts 'Running without SimpleCov'
end

require 'timecop'
require 'rails'
require 'action_controller'
require 'action_controller/test_case'
require 'action_controller/railtie'
require 'active_support/json'
require 'active_model_serializers'
require 'fileutils'
FileUtils.mkdir_p(File.expand_path('../../tmp/cache', __FILE__))

gem 'minitest'
begin
  require 'minitest'
rescue LoadError
  # Minitest 4
  require 'minitest/unit'
  require 'minitest/unit'
  require 'minitest/spec'
  require 'minitest/mock'
  $minitest_version = 4
  # https://github.com/seattlerb/minitest/blob/644a52fd0/lib/minitest/autorun.rb
  # https://github.com/seattlerb/minitest/blob/644a52fd0/lib/minitest/unit.rb#L768-L787
  # Ensure backward compatibility with Minitest 4
  Minitest = MiniTest unless defined?(Minitest)
  Minitest::Test = MiniTest::Unit::TestCase
  minitest_run = ->(argv) { MiniTest::Unit.new.run(argv) }
else
  # Minitest 5
  require 'minitest'
  require 'minitest/spec'
  require 'minitest/mock'
  $minitest_version = 5
  # https://github.com/seattlerb/minitest/blob/e21fdda9d/lib/minitest/autorun.rb
  # https://github.com/seattlerb/minitest/blob/e21fdda9d/lib/minitest.rb#L45-L59
  minitest_run = ->(argv) { Minitest.run(argv) }
end
require 'minitest/reporters'
Minitest::Reporters.use!

require 'support/rails_app'

require 'support/test_case'

require 'support/serialization_testing'

require 'support/rails5_shims'

require 'fixtures/active_record'

require 'fixtures/poro'

ActiveSupport.on_load(:action_controller) do
  $action_controller_logger = ActiveModelSerializers.logger
  ActiveModelSerializers.logger = Logger.new(IO::NULL)
end

END {
  code = minitest_run.call(ARGV)
  exit code
}
