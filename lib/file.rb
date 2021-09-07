
require 'digest'
require_relative 'file_sampler'
require_relative 'callable_hash'
require_relative 'anchor'

module AsSizeFileHash

  def singles_by_size
    clone.delete_if { |size, files| files.length == 1 }
  end

  def groups_by_size
    clone.delete_if { |size, files| files.length < 2 }
  end

  def delete_singles
    delete_if { |size, files| files.length < 2 }
  end

  def delete_groups
    delete_if { |size, files| files.length > 1 }
  end

  def potential_dups_stats
    total_size = 0
    dup_size = 0
    total_count = 0
    dup_count = 0
    each do |size, files|
      if files.length > 1
	dup_count += files.length - 1
	dup_size += size * (files.length - 1)
	total_size += size * files.length
	total_count += files.length
      end
    end
    OpenStruct.new :total_count => total_count, :dup_count => dup_count, :dup_size => dup_size, :total_size => total_size
  end

  def sizes
    keys
  end

  def groups
    values
  end

  def files
    groups.flatten
  end

  def sizes_ordered order = :asc
    raise ArgumentError, '<order> must be :asc or :desc' unless [ :asc, :desc ].include? order
    sizes = keys.sort
    sizes.reverse! if order == :desc
    return sizes
  end

  def size_total
    reduce(0) { |a,v| a + v[0] * v[1].length }
  end

  def each_by_size order = :asc
    sizes_ordered(order).each do |size|
      size_file_group = self[size]
      yield size, size_file_group
    end
  end

  def each_by_size_with_progress order = :asc
    anchor_start_end 'each_by_size' do
      progress = CallableHash::Restricted.new :size_file_group, :files_size,
					      :groups_processed => 0, :group_count => length,
					      :files_processed => 0, :file_count => file_count,
					      :size_processed => 0, :size_total => size_total,
					      :percent => 0, :complete => false
      each_by_size do |size, size_file_group|
	progress.merge(:size_file_group => size_file_group, :files_size => size).anchor 'each_by_size/progress'
	yield size, size_file_group
	progress.groups_processed += 1
	progress.files_processed += size_file_group.length
	progress.size_processed += size * size_file_group.length
	progress.percent = ((progress.files_processed * 100 / progress.file_count) + (progress.size_processed * 100 / progress.size_total)) / 2
      end
      progress.update(:complete => true).anchor 'each_by_size/progress'
    end
  end

  def file_count
    files.length
  end

end

class File

  # create sparse file at <path> of <size>
  def self.create_sparse path, size
    raise ArgumentError, "file already exists: #{path}" if File.exists? path
    system("dd if=/dev/zero of='#{path}' bs=1 count=0 skip=#{size} seek=#{size} > /dev/null 2>&1")
    raise 'failed to create sparse file', path if $? != 0
    nil
  end

  def self.digests files, digest_type = Digest::SHA2
    files.group_by { |file| digest_type.file file }
  end

  def self.group_by_size *paths
    file_sizes = Hash.new { |h,k| h[k] = FilePathArray.new }
    anchor_start_end 'group_by_size', file_sizes do
      file_count = paths.length
      progress = CallableHash::Restricted.new :percent, :complete_count, :file, :file_count => file_count
      paths.each_with_index do |file, index|
	progress.update :file => file, :complete_count => index, :percent => (index + 1) * 100 / file_count
	progress.anchor 'group_by_size/progress'
	yield index, file_count if block_given?
	fstat = File.stat file
	raise ArgumentError, "#{path} is not a regular file" unless fstat.file?
	file_sizes[fstat.size] << file if fstat.size > 0
      end
      progress.update :complete_count => file_count, :percent => 100
      progress.anchor 'group_by_size/progress'
      yield file_count, file_count if block_given?
      file_sizes.extend AsSizeFileHash
    end
  end

  def self.absolute_path path
    if path[0] == ?/ then
      path
    else
      File.join(Dir.pwd, path)
    end
  end

end

module AsFilePathArray

  def samplers size = nil
    map { |path| File::Sampler.new path, size }.extend File::AsSamplerArray
  end

end

class FilePathArray < Array

  include AsFilePathArray

end

# vim: foldmethod=syntax
