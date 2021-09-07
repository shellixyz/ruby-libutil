
require 'digest'

module AsFileSamplerArray

  def paths
    map &:path
  end

  def group_paths_by_digest
    group_by_digest.tap { |digest, group| group.map! &:path }
  end

  def groups
    group_by_digest.values
  end

  def path_groups
    group_by_digest.values.map! { |file_digests| file_digests.map &:path }
  end

  def group_by_digest
    group_by &:hexdigest
  end

  def group_paths_by_digest_without_singles
    group_paths_by_digest.delete_if { |digest, group| group.length < 2 }
  end

  def split_singles
    singles = []
    groups_without_singles = groups.delete_if { |group| group.length < 2 ? (singles << group.first; true) : false }
    [ singles.extend(AsFileDigestArray), groups_without_singles.flatten.extend(AsFileDigestArray) ]
  end

  def without_singles
    group_by_digest.values.find_all { |g| g.length > 1 }.flatten.extend(AsFileDigestArray)
  end

  def singles
    group_by_digest.values.find_all { |g| g.length == 1 }.flatten.extend(AsFileDigestArray)
  end

  def dup_group_paths
    path_groups.find_all { |group| group.length > 1 }
  end

  def group_counts
    path_groups.map { |files| files.length }
  end

  def has_dups?
    groups.any? { |files| files.length > 1 or files.any? { |file| file.total_read == 0 } }
  end

  def read(size)
    each { |file_digest| file_digest.read size }
    self
  end

  def read_upto total_size
    each &:read_upto
    self
  end

  def read_full
    each_with_index do |file_digest, index|
      yield index if block_given?
      file_digest.read_full
    end
    yield length if block_given?
    self
  end

  def rewind
    each &:rewind
    self
  end

  def seek *args
    each { |fd| fd.seek *args }
  end

  def open
    each &:open
    self
  end

  def close
    each &:close
    self
  end

  def sample
    any? { |fd| fd.open { fd.sample } }
  end

end

class FileDigestArray < Array

  #include AsFileDigestArray

  def self.from_path_array path_array, size = nil
    path_array.map { |path| FileDigest.new path, size }.extend AsFileDigestArray
  end

end

class FileSampler

  module Error
    class EndOfFile < StandardError; end
  end

  class SHA2 < self

    def initialize(*args)
      self.digest_class = Digest::SHA2
      super *args
    end

  end

  DEFAULT_DIGEST = Digest::SHA2
  DEFAULT_SAMPLE_COUNT = 5
  DEFAULT_SAMPLE_SIZE = 512

  def initialize file_path, size = nil
    self.digest_class = DEFAULT_DIGEST if self.class == FileSampler
    @path = file_path
    @sample_count = DEFAULT_SAMPLE_COUNT
    @sample_size = DEFAULT_SAMPLE_SIZE
    init_sample_seeks
    if block_given?
      open
      yield self
      close
    end
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

  def file!
    open
    @file
  end

  def digest_class=(digest_class)
    @digest_class = digest_class
    init_digest
    rewind
  end

  def rewind
    file.rewind if opened?
    digest.reset
  end

  def hexdigest
    assert_digest
    digest.hexdigest
  end

  def full_digest
    rewind
    open
    buf = ''
    digest << buf while file.read 16384, buf
    hexdigest
  end

  def sample
    open
    @sample_data ||= ''
    if sample_seek = sample_seeks.shift
      seek sample_seek
      @sample_data = nil unless read sample_size, sample_data
      sample_data
    end
  end

  def sample_digest
    hexdigest if sample
  end

  def samples_digests
    rewind
    open
    buf = ''
    sample_seeks.map do |seek_pos|
      file.seek seek_pos
      read sample_size, buf
    end
  end

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
    sample_seeks.empty?
  end

  attr_reader :path, :file, :digest_class, :sample_count, :sample_size, :sample_data, :sample_seeks

  private

  attr_reader :digest

  def seek *args
    file.seek *args
  end

  def read *args
    assert_digest
    file.read(*args).tap { |buf| digest << buf }
  end

  def assert_digest
    raise 'digest class is not initialized' unless defined? @digest_class
  end

  def init_digest
    @digest = digest_class.new
  end

  def init_sample_seeks
    interval = (size - sample_count * sample_size) / (sample_count - 1) + sample_size
    @sample_seeks = (0...sample_count).map { |si| si * interval }
  end

end

module AsFilePathArray

  def file_samplers size = nil
    FileDigestArray.from_path_array self, size
  end

  def digests
    File.digests self
  end

  def dups_read_full
    digests.values.reject { |files| files.length < 2 }.extend AsGroupArray
  end

  def file_digests size = nil
    FileDigestArray.from_path_array self, size
  end

end

class FileDigest

  module Error
    class EndOfFile < StandardError; end
  end

  class SHA2 < self

    def initialize(*args)
      self.digest_class = Digest::SHA2
      super *args
    end

  end

  DEFAULT_DIGEST = Digest::SHA2

  def initialize(file_path, size = nil)
    self.digest_class = DEFAULT_DIGEST if self.class == FileDigest
    @path = file_path
    @total_read = 0
    if block_given?
      open
      yield self
      close
    end
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
      file.seek total_read
    end
    if block_given?
      yield
      close
    end
    self
  end

  def file!
    open
    @file
  end

  def digest_class=(digest_class)
    @digest_class = digest_class
    init_digest
    rewind
  end

  def rewind
    file.rewind if opened?
    @total_read = 0
    digest.reset
  end

  def read rsize
    assert_digest
    buffer = file!.read rsize
    raise Error::EndOfFile, "end of file reached: #{path}" if buffer.nil?
    @total_read += buffer.length
    digest << buffer
    hexdigest
  end

  def eof?
    opened? ? file.eof? : (total_read == size)
  end

  def hexdigest
    assert_digest
    digest.hexdigest
  end

  def read_full
    assert_digest
    open
    buf = ''
    digest << buf while file.read 16384, buf
    @total_read = size
    hexdigest
  end

  def read_upto total_size
    raise ArgumentError, "already beyond requested pos: #{path}" if total_read > total_size
    raise ArgumentError, "trying to read beyond the end of file: #{path}" if total_size > size
    read(total_size - total_read)
  end

  def sample_seeks_init
    interval = (size - sample_count * sample_size) / (sample_count - 1) + sample_size
    @sample_seeks = (0...sample_count).map { |si| si * interval }
  end

  def read_sample
  end

  def read_samples
    rewind
    open
    buf = ''
    sample_seeks.each { file.read sample_size, buf }
    hexdigest
  end

  def sample_count=
  end

  def sample_size=
  end

  #def read_samples
  #  rewind
  #  open
  #  buf = ''
  #  sample_count.map do |stripe_index|
  #    puts "sampling #{stripe_index} pos: #{file.pos}"
  #    break unless file!.read sample_size, buf
  #    puts "read #{buf.length}"
  #    digest << buf
  #    yield hexdigest if block_given?
  #    new_pos = size * (stripe_index + 1) / sample_count
  #    file.seek new_pos if new_pos > file.pos
  #    hexdigest
  #  end
  #end

  def seek *args
    file.seek *args if opened?
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

  attr_reader :path, :file, :total_read, :digest_class, :sample_count, :sample_size

  private

  attr_reader :digest

  def assert_digest
    raise 'digest class is not initialized' unless defined? @digest_class
  end

  def init_digest
    @digest = digest_class.new
  end

end

module AsFileDigestArray

  def open
    each &:open
  end

  def close
    each &:close
  end

  def groups
    group_by(&:hexdigest).values
  end

  def path_groups
    #STDERR.puts "Warning: #{__FILE__}:#{__LINE__} path_groups: to check"
    #groups.values
    groups.map { |group| group.map &:path }
  end

  def group_counts
    #STDERR.puts "Warning: #{__FILE__}:#{__LINE__} group_factors: to check"
    #path_groups.map &:length
    groups.map &:length
  end

  def read rsize
    #STDERR.puts "Warning: #{__FILE__}:#{__LINE__} read: to check"
    each { |x| x.read rsize }
  end

  def read_full
    each do |file_digest|
      file_digest.read_full
      file_digest.close
    end
  end

  def split_singles
    #STDERR.puts "Warning: #{__FILE__}:#{__LINE__} split_singles: to check"
    singles = []
    others = []
    #path_groups.each { |g| (g.length > 1 ? others : singles) << g }
    groups.each do |g|
      if g.length > 1
	others.concat g
      else
	singles.concat g
	#singles << g[0]
      end
    end
    singles.extend AsFileDigestArray
    others.extend AsFileDigestArray
    #require 'pp'
    #pp others
    [ singles, others ]
  end

end

#module AsFilePathArray

  #def file_digests size = nil
    #FileDigestArray.from_path_array self, size
  #end

  #def file_digests size = nil
    #FileSamplerArray.from_path_array self, size
  #end

  #def digests
    #File.digests self
  #end

  #def dups_read_full
    #digests.values.reject { |files| files.length < 2 }.extend AsGroupArray
  #end

#end

# vim: foldmethod=syntax
