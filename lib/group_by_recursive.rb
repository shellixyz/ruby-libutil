
module Enumerable

  # Example:
  # X = Struct.new :a, :b, :c
  # a = [
  #   X.new(0, 1, 1),
  #   X.new(0, 1, 2),
  #   X.new(0, 2, 3),
  #   X.new(0, 2, 4),
  #   X.new(1, 3, 5),
  #   X.new(1, 3, 6),
  #   X.new(1, 4, 7),
  #   X.new(1, 4, 8),
  # ]
  # pp a.group_by_recursive :a, :b
  def group_by_recursive *props
    raise ArgumentError, 'wrong number of arguments (given 0, expected at least 1)' if props.empty?
    groups = group_by &props.first
    if props.count == 1
      groups
    else
      groups.merge(groups) do |group, elements|
        elements.group_by_recursive *props.drop(1)
      end
    end
  end

end

if $0 == __FILE__
    puts "group_by_recursive example:"
    X = Struct.new :a, :b, :c
    a = [
        X.new(0, 1, 1),
        X.new(0, 1, 2),
        X.new(0, 2, 3),
        X.new(0, 2, 4),
        X.new(1, 3, 5),
        X.new(1, 3, 6),
        X.new(1, 4, 7),
        X.new(1, 4, 8),
    ]
    puts 'Ungrouped:'
    pp a
    puts
    puts 'Grouped:'
    pp a.group_by_recursive :a, :b
end
