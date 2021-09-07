
require 'benchmark'
require_relative '../../lib/callbacks'

include Benchmark

pr = proc { }
cb = Callbacks::Callback.new &pr
cs = Callbacks::Sequence.new [ pr ]
sm = Callbacks::SmartCallback.new(:map, &pr)

bm(16) do |x|
  x.report('proc') { 1_000_000.times { pr.call } }
  x.report('callback') { 1_000_000.times { cb.call } }
  x.report('sequence') { 1_000_000.times { cs.call } }
  x.report('smart_callback') { 1_000_000.times { sm.call [1] } }
end

