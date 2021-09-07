
require 'digest'

module File::AsSamplerArray

  def paths
    map &:path
  end

  def group_by_digest
    group_by &:hexdigest
  end

  def groups
    group_by_digest.values
  end

  def path_groups
    group_by_digest.values.map! { |file_digests| file_digests.map &:path }
  end

  def sample!
    #not map { |fd| fd.open { fd.sample! } }.all? &:nil?
    not map { |fd| fd.sample! }.all? &:nil?
  end

  def remove_singles
    old_length = length
    replace groups.delete_if { |group| group.length < 2 }.flatten!
    old_length - length
  end

  def group_duplicates!
    rewind
    done_count = 0
    yield done_count if block_given?
    while not groups.empty? and sample!
      done_count += remove_singles
      yield done_count if block_given?
    end
    paths.group_by do |path|
      Digest::SHA2.file(path).tap do
	done_count += 1
	yield done_count if block_given?
      end
    end.values
  end

  def find_duplicate! file
    file_sampler = File::Sampler.new file
    pdup_count = length
    dup = find.with_index do |pdup_sampler, pdup_index|
      yield pdup_index if block_given?
      (file_sampler.samples_digests! == pdup_sampler.samples_digests! and file_sampler.full_digest! == pdup_sampler.full_digest!).tap { pdup_sampler.close }
    end
    yield pdup_count if block_given?
    dup.path unless dup.nil?
  end

  def find_duplicates! file
    file_sampler = File::Sampler.new file
    done_count = 0
    yield 0 if block_given?
    while not groups.empty? and sample! and file_sampler.sample!
      if mismatches = reject! { |pdup_sampler| pdup_sampler.hexdigest != file_sampler.hexdigest }
        done_count += mismatches.length
        yield done_count if block_given?
      end
    end
    delete_if do |pdup_sampler|
      (pdup_sampler.full_digest! != file_sampler.full_digest!).tap do
        done_count += 1
        yield done_count if block_given?
      end
    end
    paths
  end

  def rewind
    each &:rewind
  end

end

module Enumerator::Comparable

  def == other_enum
    loop do
      has_lvalue, has_rvalue = true, true
      lvalue =
        begin
          self.next
        rescue StopIteration
          has_lvalue = false
        end
      rvalue =
        begin
          other_enum.next
        rescue StopIteration
          has_rvalue = false
        end
      if has_lvalue != has_rvalue
        return false
      else
        if has_lvalue
          return false if lvalue != rvalue
        else
          return true
        end
      end
    end
  end

end

class File::Sampler

  class SHA2 < self

    def initialize(*args)
      @digest_class = Digest::SHA2
      super *args
    end

  end

  DEFAULT_DIGEST = Digest::SHA2
  DEFAULT_SAMPLE_COUNT_MAX = 5
  DEFAULT_SAMPLE_SIZE = 1
  DEFAULT_INTERSAMPLE_SIZE = 10
  DEFAULT_BLOCK_SIZE = 4096

  def initialize file_path, size = nil
    @path = file_path
    @sample_count_max = DEFAULT_SAMPLE_COUNT_MAX
    @sample_size_blocks = DEFAULT_SAMPLE_SIZE
    @block_size = DEFAULT_BLOCK_SIZE
    @sample_size = sample_size_blocks * block_size
    @intersample_size = DEFAULT_INTERSAMPLE_SIZE
    @size = size
    init_digest DEFAULT_DIGEST
    init_sample_seeks
    if block_given?
      open
      yield self
      close
    end
  end

  def inspect
    "#<#{self.class} #{path}>"
  end

  def size
    @size ||= opened? ? file.stat.size : File.size(path)
  end

  def refresh_size!
    @size = File.size path
    self
  end

  def open
    unless opened?
      raise ArgumentError, "#{path} is not a regular file" unless File.file? path
      @file = File.open path
    end
    if block_given?
      yield(self).tap { close }
    else
      self
    end
  end

  def close
    if file
      file.close
      @file = nil
    end
    nil
  end

  def opened?
    not @file.nil?
  end

  def file
    open
    @file
  end

  def digest_class= digest_class
    init_digest digest_class
    rewind
  end

  def rewind
    file.rewind if opened?
    init_sample_seeks
    digest.reset
    @samples_digests = nil
    @sample_data = nil
    @full_digest = nil
  end

  def hexdigest
    assert_digest
    digest.hexdigest
  end

  def full_digest!
    return @full_digest if @full_digest
    rewind
    open
    buf = ''
    digest << buf while file.read 16384, buf
    @full_digest = hexdigest
  end

  def sample!
    #open
    @sample_data ||= ''
    if sample_seek = samples_seeks.shift
      seek sample_seek
      @sample_data = nil unless read sample_size, sample_data
      sample_data
    end
  end

  def sample_digest!
    hexdigest if sample!
  end

  def samples_digests!
    return nil if sampling_complete?
    @samples_digests ||= []
    digest.reset
    Enumerator.new do |yielder|
      index = 0
      loop do
        unless sample_digest = samples_digests[index]
          sample_digest = sample_digest!
          break if sample_digest.nil?
          samples_digests[index] = sample_digest
        end
        yielder.yield sample_digest
        index += 1
      end
    end.extend Enumerator::Comparable
  end

  #def each_sample_digest!
  #  @sample_digests ||= []
  #  index = 0
  #  loop do
  #    unless sample_digest = sample_digests[index]
  #      sample_digest = sample_digest!
  #      break if sample_digest.nil?
  #      sample_digests[index] = sample_digest
  #    end
  #    yield sample_digest
  #    index += 1
  #  end
  #end

  #def samples_digests
  #  rewind
  #  open
  #  buf = ''
  #  sample_seeks.map do |seek_pos|
  #    file.seek seek_pos
  #    read sample_size, buf
  #  end
  #end

  def sample_count= value
    @sample_count = value
    rewind
    init_sample_seeks
  end

  def sample_size= value
    @sample_size = value
    rewind
    init_sample_seeks
  end

  def sampling_complete?
    samples_seeks.empty?
  end

  attr_reader :path, :digest_class, :block_size, :sample_count, :sample_count_max, :intersample_size, :sample_size, :sample_size_blocks, :sample_data, :samples_seeks, :samples_digests

  private

  attr_reader :digest

  def seek *args
    puts "seeking #{args.inspect}"
    file.seek *args
  end

  def read *args
    puts "reading #{args.inspect}"
    assert_digest
    file.read(*args).tap { |buf| digest << buf }
  end

  def assert_digest
    raise 'digest class is not initialized' unless defined? @digest_class
  end

  def init_digest new_digest_class = nil
    #@digest = digest_class.new
    @digest_class = new_digest_class if new_digest_class
    @digest = digest_class.new
  end

  def init_sample_seeks
    #@samples_seeks =
      #if size < sample_size
        #[]
      #else # 0 1K 1.5K 2K 2.5K => min 3K et ça veut encore dire plus de 50% du fichier lu => c'est trop
        # XXX: ça va pas: il faut faire en sorte que ça renvoie des samples blocks qui lisent au maximum la moitié du fichier
        # ex (sample_size=512): jusqu'à 1,5K: 0, jusqu'à 2,5K: 0; 1024, jusqu'à 3.5K: 0; 1024; 2048
        # correction: en dessous d'une certaine taille il faut coller les samples: jusquà 4K: 0->512; jusqu'à
        #@sample_count = size / sample_size if size < sample_count * sample_size
        #interval = (size - sample_count * sample_size) / (sample_count - 1) + sample_size
        #interval < 2 * sample_size ? [] : (0...sample_count).map { |si| si * interval }
      #end

    #interval_min = sample_size * (intersample_size + 1)
    #@sample_count = size / interval_min
    #@sample_count += 1 if size - sample_size * (sample_count + sample_count * intersample_size) >= sample_size
    #@samples_seeks =
      #if sample_count < 1 or sample_count * sample_size >= 0.5 * size
	#[]
      #elsif sample_count > sample_count_max
	#@sample_count = sample_count_max
	#interval = (size - sample_count * sample_size) / (sample_count - 1) + sample_size
	#seeks = (0...sample_count).map { |si| pos = si * interval; pos + pos % block_size }
	#seeks.delete_at(-1) if seeks.last > size - sample_size
	#seeks
      #else
	#(0...sample_count).map { |si| si * interval_min }
      #end

    block_count = size / block_size
    sample_count = block_count / (sample_size_blocks + intersample_size)
    sample_count += 1 if sample_count * (sample_size_blocks + intersample_size) < block_count
    return [] if sample_count < 1 or sample_count * block_size >= 0.5 * size
    if sample_count > sample_count_max
      sample_count = sample_count_max
      intersample_size = (block_count - sample_count * sample_size_blocks) / (sample_count - 1)
    end
    @samples_seeks = (0...sample_count).map { |si| si * (sample_size_blocks + intersample_size) * block_size }
  end

end
