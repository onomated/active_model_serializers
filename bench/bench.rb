require 'benchmark'
def run
  n = 10_000_000
  puts "running #{n} times"
  result =  Benchmark.bmbm do |x|
    x.report('no_cache') do |times|
      times ||= n
      benchmark_caching(false, times)
    end
    x.report('cache') do |times|
      times ||= n
      benchmark_caching(true, times)
    end
  end
  # p result
end
def benchmark_caching(on, times)
  # reader, writer = IO.pipe
  caching = on ? '0' : '1'
  _bundle_command = Gem.bin_path('bundler', 'bundle')
  out = IO::NULL
  # out = STDOUT
  pid = spawn(
    { 'DISABLE_CACHE' => caching, 'TIMES' =>  times.to_s},
    "#{Gem.ruby} #{_bundle_command} exec ruby -Itest test/benchmark_test.rb",
    out: out
  )
  trap(:INT) do
    Process.kill(:INT, pid)
    exit
  end
  Process.wait(pid)
  # Process.detach(pid)
end
# def bundle_command(command)
#   # We are going to shell out rather than invoking Bundler::CLI.new(command)
#   # because `rails new` loads the Thor gem and on the other hand bundler uses
#   # its own vendored Thor, which could be a different version. Running both
#   # things in the same process is a recipe for a night with paracetamol.
#   #
#   # We use backticks and #print here instead of vanilla #system because it
#   # is easier to silence stdout in the existing test suite this way. The
#   # end-user gets the bundler commands called anyway, so no big deal.
#   #
#   # We unset temporary bundler variables to load proper bundler and Gemfile.
#   #
#   # Thanks to James Tucker for the Gem tricks involved in this call.
#   _bundle_command = Gem.bin_path('bundler', 'bundle')
#
#   require 'bundler'
#   Bundler.with_clean_env do
#     output = `"#{Gem.ruby}" "#{_bundle_command}" #{command}`
#     print output unless options[:quiet]
#   end
# end
run
