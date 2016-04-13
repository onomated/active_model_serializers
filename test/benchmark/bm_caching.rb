require_relative './benchmarking_support'
require_relative './app'

# https://github.com/ruby-bench/ruby-bench-suite/blob/8ad567f7e43a044ae48c36833218423bb1e2bd9d/rails/benchmarks/actionpack_router.rb
class ApiAssertion
  include Benchmark::ActiveModelSerializers::TestMethods
  BadRevisionError = Class.new(StandardError)

  def valid?
    caching = get_caching
    caching[:body].delete('meta')
    non_caching = get_non_caching
    non_caching[:body].delete('meta')
    assert_responses(caching, non_caching)
  rescue BadRevisionError => e
    msg = { error: e.message }
    STDERR.puts msg
    STDOUT.puts msg
    exit 1
  end

  def get_status(on_off = 'on'.freeze)
    get("/status/#{on_off}")
  end

  def clear
    get('/clear')
  end

  def get_caching(on_off = 'on'.freeze)
    get("/caching/#{on_off}")
  end

  def get_non_caching(on_off = 'on'.freeze)
    get("/non_caching/#{on_off}")
  end

  def debug(msg = '')
    if block_given? && ENV['DEBUG'] =~ /\Atrue|on|0\z/i
      STDERR.puts yield
    else
      STDERR.puts msg
    end
  end

  private

  def assert_responses(caching, non_caching)
    assert_equal(caching[:code], 200, "Caching response failed: #{caching}")
    assert_equal(caching[:body], expected, "Caching response format failed: \n+ #{caching[:body]}\n- #{expected}")
    assert_equal(caching[:content_type], 'application/json; charset=utf-8', "Caching response content type  failed: \n+ #{caching[:content_type]}\n- application/json")
    assert_equal(non_caching[:code], 200, "Non caching response failed: #{non_caching}")
    assert_equal(non_caching[:body], expected, "Non Caching response format failed: \n+ #{non_caching[:body]}\n- #{expected}")
    assert_equal(non_caching[:content_type], 'application/json; charset=utf-8', "Non caching response content type  failed: \n+ #{non_caching[:content_type]}\n- application/json")
  end

  def get(url)
    response = request(:get, url)
    { code: response.status, body: JSON.load(response.body), content_type: response.content_type }
  end

  def expected
    @expected ||=
      {
        'post' =>  {
          'id' =>  1337,
          'title' => 'New Post',
          'body' =>  'Body',
          'comments' => [
            {
              'id' => 1,
              'body' => 'ZOMG A COMMENT'
            }
          ],
          'blog' =>  {
            'id' =>  999,
            'name' => 'Custom blog'
          },
          'author' => {
            'id' => 42,
            'first_name' => 'Joao',
            'last_name' => 'Moura'
          }
        }
    }
  end

  def assert_equal(expected, actual, message)
    return true if expected == actual
    if ENV['FAIL_ASSERTION'] =~ /\Atrue|on|0\z/i # rubocop:disable Style/GuardClause
      fail BadRevisionError, message
    else
      STDERR.puts message unless ENV['SUMMARIZE']
    end
  end
end
assertion = ApiAssertion.new
assertion.valid?
assertion.debug { assertion.get_status }

time = 10
require 'ruby-prof'
# GC.enable_stats
prof_target = 'MEMORY' # ARGV[0]
RubyProf.measure_mode = RubyProf.const_get(prof_target)
{
  'caching on: caching serializers: gc off' => { disable_gc: true, send: [:get_caching, 'on'] },
  'caching on: non-caching serializers: gc off' => { disable_gc: true, send: [:get_non_caching, 'on'] },
  'caching off: caching serializers: gc off' => { disable_gc: true, send: [:get_caching, 'off'] },
  'caching off: non-caching serializers: gc off' => { disable_gc: true, send: [:get_non_caching, 'off'] }
}.each do |label, options|
  assertion.clear
  # result = RubyProf.profile do
    Benchmark.ams(label, time: time, disable_gc: options[:disable_gc]) do
      assertion.send(*options[:send])
    end
  # end
  # min_percent = 5
  # print = ->(printer, name) do
  #   io = File.open("#{prof_target}_#{name}", "w+")
  #     printer.print(io)
  #   # end
  # end
  # # Let me first explain what the columns in the report mean.
  #   # %self The percentage of the time spent only in this function. See the definition of self.
  #   # total The total time spent in this function, including the execution time of functions that it calls.
  #   # self The time spent only in this function, excluding the execution time of functions that it calls.
  #   # wait The time spent waiting for other threads. This will always be zero for single-threaded apps. I’ll sometimes omit this column from profiles included in this book to save some space.
  #   # child The time spent in functions that are called from the current function. calls The total number of calls to this function.
  #   # The flat report is sorted by self time. So functions at the top of the report are the ones where our program spends most of the time.
  # print.(RubyProf::FlatPrinter.new(result), "_optimized_profile.txt")
  # print.(RubyProf::CallTreePrinter.new(result), "_callgrind.out.memprof_app")
  # print.(RubyProf::GraphPrinter.new(result), "_graph_profile.txt")
  # print.(RubyProf::GraphHtmlPrinter.new(result), "_graph_profile.html")
  # # % of total time (% of caller time) Function [# of calls, # of calls total]
  # print.(RubyProf::CallStackPrinter.new(result), "_call_stack_profile.html")
  #
  assertion.debug { assertion.get_status(options[:send][-1]) }
end
