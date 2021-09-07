
require 'yaml'

module YAML

  def self.load_file_if_exists file
    load_file file
  rescue Errno::ENOENT
  end

end
