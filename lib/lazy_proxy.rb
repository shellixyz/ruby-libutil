
# The block given to LazyProxy.new is evaluated only when the first method is called
# The value returned by the block is kept and all the methods forwarded to it
#
# proxy = LazyProxy.new { [1, 2, 3] } # block isn't called
# proxy.count # block is called and count is called on the returned value => 3
# proxy.length # length is called on saved value returned previously by the block

class LazyProxy

  def initialize &block
    @block = block
  end

  def method_missing method, *args, &block
    value = @block_called ? @value : @value = @block.call.tap { @block_called = true }
    value.respond_to?(method) ? value.send(method, *args, &block) : super
  end

end
