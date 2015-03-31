begin
  require 'simplecov'
rescue LoadError
end

require 'bundler/gem_tasks'

begin
  require 'rubocop'
  require 'rubocop/rake_task'
rescue LoadError
else
  Rake::Task[:rubocop].clear if Rake::Task.task_defined?(:rubocop)
  require 'rbconfig'
  # https://github.com/bundler/bundler/blob/1b3eb2465a/lib/bundler/constants.rb#L2
  windows_platforms = /(msdos|mswin|djgpp|mingw)/
  if RbConfig::CONFIG['host_os'] =~ windows_platforms
    desc 'No-op rubocop on Windows-- unsupported platform'
    task :rubocop do
      puts 'Skipping rubocop on Windows'
    end
  elsif defined?(::Rubinius)
    desc 'No-op rubocop to avoid rbx segfault'
    task :rubocop do
      puts 'Skipping rubocop on rbx due to segfault'
      puts 'https://github.com/rubinius/rubinius/issues/3499'
    end
  else
    Rake::Task[:rubocop].clear if Rake::Task.task_defined?(:rubocop)
    desc 'Execute rubocop'
    RuboCop::RakeTask.new(:rubocop) do |task|
      task.options = ['--rails', '--display-cop-names', '--display-style-guide']
      task.fail_on_error = true
    end
  end
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
  t.ruby_opts = ['-r./test/test_helper.rb']
  t.verbose = true
end

task default: [:test, :rubocop]

desc 'CI test task'
task :ci => [:default]

require 'rugged'
require 'benchmark'
Rake::TestTask.new :benchmark_tests do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_benchmark.rb']
  t.ruby_opts = ['-r./test/test_helper.rb']
  t.verbose = true
end

task :benchmark do
  @repo = Rugged::Repository.new('.')
  ref   = @repo.head

  actual_branch = ref.name

  set_commit('master')
  old_bench = Benchmark.realtime { Rake::Task['benchmark_tests'].execute }

  set_commit(actual_branch)
  new_bench = Benchmark.realtime { Rake::Task['benchmark_tests'].execute }

  puts 'Results ============================'
  puts "------------------------------------~> (Branch) MASTER"
  puts old_bench
  puts "------------------------------------"

  puts "------------------------------------~> (Actual Branch) #{actual_branch}"
  puts new_bench
  puts "------------------------------------"
end

def set_commit(ref)
  @repo.checkout ref
end
