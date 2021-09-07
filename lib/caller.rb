
module Kernel

  CallerMethod = Struct.new :source_path, :line, :method

  def caller_details
    caller[1..-1].map do |caller_line|
      md = caller_line.match(/\A(?<path>.+):(?<line>\d+):in `(?<method>.+)'\Z/)
      CallerMethod.new md[:path], md[:line], md[:method]
    end
  end

  def direct_caller_source_path
    caller_details[1].source_path
  end

  def direct_caller_source_dir
    File.dirname caller_details[1].source_path
  end

end
