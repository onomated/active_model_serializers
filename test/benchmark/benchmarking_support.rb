require 'json'

# Add benchmarking runner from ruby-bench-suite
# https://github.com/ruby-bench/ruby-bench-suite/blob/master/rails/benchmarks/support/benchmark_rails.rb
module Benchmark
  module ActiveModelSerializers
    module TestMethods
      def request(method, path)
        response = Rack::MockRequest.new(BenchmarkApp).send(method, path)
        if response.status.in?([404, 500])
          fail "omg, #{method}, #{path}, '#{response.status}', '#{response.body}'"
        end
        response
      end
    end
    module FakeIps
      ITERATIONS = 50

      # rubocop:disable Metrics/AbcSize
      def ips(*args)
        if args[0].is_a?(Hash)
          time, warmup, = args[0].values_at(:time, :warmup, :quiet)
        else
          time, warmup, = args
        end

        sync = $stdout.sync
        $stdout.sync = true

        job = Class.new do
          attr_reader :label, :result

          def initialize(time, warmup)
            @time = time
            @warmup = warmup
          end

          def report(_label, &blk)
            cycles = ITERATIONS
            Benchmark.measure do
              @warmup.times do
                cycles.times(&blk)
              end
            end
            timings = []
            @time.times do
              timings << Benchmark.measure do
                cycles.times(&blk)
              end.total # user + system
            end
            @all_ips = timings.map do |time_us|
              cycles.to_f / time_us.to_f
            end
            self
          end

          # avg_ips = Timing.mean(all_ips)
          # rubocop:disable Style/SingleLineBlockParams
          #   Name inject block params |a, e|
          def ips
            @ips_mean ||=
              begin
                sum = @all_ips.inject(0) { |acc, i| acc + i }
                sum / @all_ips.size
              end
          end

          # sd_ips =  Timing.stddev(all_ips, avg_ips).round
          def stddev_percentage
            @sd_ips ||=
              begin
                m = ips
                total = @all_ips.inject(0) { |acc, i| acc + ((i - m)**2) }.to_f
                variance = total / (@all_ips.size - 1).to_f
                Float(Math.sqrt(variance)).round
              end
          end
          # rubocop:enable Style/SingleLineBlockParams
        end.new(time, warmup)

        entry = yield job

        $stdout.sync = sync

        report = Class.new do
          attr_reader :entries
          def initialize(entries)
            @entries = Array(entries)
          end
        end
        report.new(entry)
      end
      # rubocop:enable Metrics/AbcSize
    end

    # extend Benchmark with an `ams` method
    def ams(label = nil, time:, disable_gc: true, warmup: 3, &block)
      fail ArgumentError.new, 'block should be passed' unless block_given?

      if disable_gc
        GC.disable
      else
        GC.enable
      end

      report = Benchmark.ips(time, warmup, true) do |x|
        x.report(label) { yield }
      end

      entry = report.entries.first

      output = {
        label: label,
        version: ::ActiveModel::Serializer::VERSION.to_s,
        rails_version: ::Rails.version.to_s,
        iterations_per_second: entry.ips,
        iterations_per_second_standard_deviation: entry.stddev_percentage,
        total_allocated_objects_per_iteration: count_total_allocated_objects(&block)
      }.to_json

      puts output
      output
    end

    def count_total_allocated_objects
      if block_given?
        key =
          if RUBY_VERSION < '2.2'
            :total_allocated_object
          else
            :total_allocated_objects
          end

        before = GC.stat[key]
        yield
        after = GC.stat[key]
        after - before
      else
        -1
      end
    end
  end


  require 'benchmark/ips'
  # extend Benchmark::ActiveModelSerializers::FakeIps
  extend Benchmark::ActiveModelSerializers
end
# puts "memory usage after large string creation %d MB" %
#   (`ps -o rss= -p #{Process.pid}`.to_i/1024)
#
# str = nil
# GC.start(full_mark: true, immediate_sweep: true)
# require 'benchmark'
#
# def performance_benchmark(name, &block)
#   # 31 runs, we'll discard the first result
#   (0..30).each do |i|
#     # force GC in parent process to make sure we reclaim
#     # any memory taken by forking in previous run
#     GC.start
#
#     # fork to isolate our run
#     pid = fork do
#       # again run GC to reduce effects of forking
#       GC.start
#       # disable GC if you want to see the raw performance of your code
#       GC.disable if ENV["RUBY_DISABLE_GC"]
#
#       # because we are in a forked process, we need to store
#       # results in some shared space.
#       # local file is the simplest way to do that
#       benchmark_results = File.open("benchmark_results_#{name}", "a")
#
#       elapsed_time = Benchmark::realtime do
#         yield
#       end
#
#       # do not count the first run
#       if i > 0
#         # we use system clock for measurements,
#         # so microsecond is the last significant figure
#         benchmark_results.puts elapsed_time.round(6)
#       end
#       benchmark_results.close
#
#       GC.enable if ENV["RUBY_DISABLE_GC"]
#     end
#     Process::waitpid pid
#   end
#
#   measurements = File.readlines("benchmark_results_#{name}").map do |value|
#     value.to_f
#   end
#   File.delete("benchmark_results_#{name}")
#
#   average = measurements.inject(0) do |sum, x|
#     sum + x
#   end.to_f / measurements.size
#   stddev = Math.sqrt(
#     measurements.inject(0){ |sum, x| sum + (x - average)**2 }.to_f /
#       (measurements.size - 1)
#   )
#
#   # return both average and standard deviation,
#   # this time in millisecond precision
#   # for all practical purposes that should be enough
#   [name, average.round(3), stddev.round(3)]
# end
#
# result = performance_benchmark("sleep 1 second") do
#   sleep 1
# end
# puts "%-28s %0.3f ± %0.3f" % result
