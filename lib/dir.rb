
class Dir

  def self.regular_files(path)
    open(path) { |d| d.regular_files }
  end

  def self.dirs(path)
    open(path) { |d| d.dirs }
  end

  def self.empty?(path)
    open(path).empty?
  end

  def self.dirs_and_rfiles_r(*adirs)
    file_count = 0
    files = []
    dirs = []
    dirs_to_scan = adirs
    while not dirs_to_scan.empty?
      new_dirs_to_scan = []
      dirs_to_scan.each do |ndir|
	begin
	  dirs << ndir
	  dir = Dir.open(ndir)
	  dir_files = dir.regular_files.map { |file| File.join(ndir, file) }
	  new_dirs_to_scan.concat dir.dirs.map { |sdir| File.join(ndir, sdir) }
	  file_count += dir_files.length
	  files.concat dir_files unless dir_files.empty?
	  dir.close
	  yield file_count, dirs.length, ndir, dir_files if block_given?
	rescue Errno::EACCES
	end
      end
      dirs_to_scan = new_dirs_to_scan
    end
    yield file_count, dirs.length, nil, nil if block_given?
    OpenStruct.new :files => files, :dirs => dirs
  end

  def regular_files
    entries.find_all { |e| not [ '.', '..' ].include? e and File.ftype(File.join(path, e)) == 'file' }
  end

  def empty?
    entries.find_all { |e| not [ '.', '..' ].include? e }.empty?
  end

  def dirs
    entries.find_all { |e| not [ '.', '..' ].include? e and File.ftype(File.join(path, e)) == 'directory' }
  end

end

module Kernel

  def in_dir(dir)
    cdir = Dir.pwd
    Dir.chdir dir
    x = yield
    Dir.chdir cdir
    return x
  end

end

# vim: foldmethod=syntax
