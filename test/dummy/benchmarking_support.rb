require 'json'

# Add benchmarking runner from ruby-bench-suite
# https://github.com/ruby-bench/ruby-bench-suite/blob/master/rails/benchmarks/support/benchmark_rails.rb
module Benchmark
  module ActiveModelSerializers
    module TestMethods
      def request(method, path)
        response = Rack::MockRequest.new(DummyApp).send(method, path)
        if response.status.in?([404, 500])
          fail "omg, #{method}, #{path}, '#{response.status}', '#{response.body}'"
        end
        response
      end
    end

    module FakeIps
      ITERATIONS = 100

      # rubocop:disable Metrics/AbcSize
      def ips(*args)
        if args[0].is_a?(Hash)
          time, warmup, = args[0].values_at(:time, :warmup, :quiet)
        else
          time, warmup, = args
        end

        sync, $stdout.sync = $stdout.sync, true

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
                total = @all_ips.inject(0) { |acc, i| acc + ((i - m)**2) }
                variance = total / @all_ips.size
                Math.sqrt(variance).round
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

      # json_path = ENV['OUTPUT_PATH']
      # STDERR.puts "Saving output to json_path '#{json_path}'"
      report = Benchmark.ips(time, warmup, true) do |x|
        x.report(label) { yield }
        # x.json!(json_path) if json_path
        # x.compare!
      end

      entry = report.entries.first

      output = {
        label: label,
        version: ::ActiveModel::Serializer::VERSION.to_s,
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

  extend Benchmark::ActiveModelSerializers
  # begin
  require 'benchmark/ips'
  # rescue LoadError
  #   extend Benchmark::ActiveModelSerializers::FakeIps
  # end
end
