
require_relative 'string'

module DataSize

  module Error

    class InvalidFormat < Exception; end

  end

  HumanUnit = Struct.new :symbol, :size_bytes, :significant_fractional_digits
  HumanVendorUnit = Struct.new :symbol, :size_bytes

  HumanUnits = [
    HumanUnit.new('B', 1, 0),
    HumanUnit.new('KB', 2**10, 2),
    HumanUnit.new('MB', 2**20, 2),
    HumanUnit.new('GB', 2**30, 2),
    HumanUnit.new('TB', 2**40, 3),
    HumanUnit.new('PB', 2**50, 3),
    HumanUnit.new('EB', 2**60, 3),
    HumanUnit.new('ZB', 2**70, 3),
    HumanUnit.new('YB', 2**80, 3)
  ]

  HumanVendorUnits = [
    HumanVendorUnit.new('B', 1),
    HumanVendorUnit.new('K', 10**3),
    HumanVendorUnit.new('M', 10**6),
    HumanVendorUnit.new('G', 10**9),
    HumanVendorUnit.new('T', 10**12),
    HumanVendorUnit.new('P', 10**15),
    HumanVendorUnit.new('E', 10**18),
    HumanVendorUnit.new('Z', 10**21),
    HumanVendorUnit.new('Y', 10**24)
  ]

  # find right unit from units to display size
  def self.find_display_unit units, size
    units.reverse.find { |unit| size > unit.size_bytes } or units.first
  end

  # return the unit size in bytes
  def self.unit_size units, unit_symbol
    units.find { |unit| unit.symbol.start_with? unit_symbol }.size_bytes
  end

  # convert input size to size string with units (^2)
  def self.make_human size
    unit = find_display_unit HumanUnits, size
    sprintf("%.#{unit.significant_fractional_digits}f#{unit.symbol}", size.to_f / unit.size_bytes)
  end

  # convert input size to size string with units (^10)
  def self.make_human_vendor size
    unit = find_display_unit HumanVendorUnits, size
    "#{size / unit.size_bytes}#{unit.symbol}"
  end

  # convert a size string with units to byte size
  def self.to_bytes human_format
    hmatch = human_format.match /^(\d+(?:\.\d+)?)([BKMGTPEZY]B?)?$/
    raise Error::InvalidFormat, "Invalid size format: #{human_format.inspect}" if hmatch.nil?
    size, unit_symbol = hmatch[1].to_numeric, hmatch[2]
    unit_size = unit_size HumanUnits, unit_symbol
    (size * unit_size).ceil
  end

  # return the number of blocks needed to contains size bytes
  def self.block_size size, block_size
    bsize = size / block_size
    bsize += 1 if size % block_size != 0
    return bsize
  end

  # return the size rounded to the upper block multiple
  def self.block_round_size size, block_size
    block_size(size, block_size) * block_size
  end

end

# vim: foldmethod=syntax
