
class Hash

  def show
    each do |key, values|
      puts key.to_s
      puts values.map { |v| '  --> ' + v.to_s }.join("\n")
    end
    nil
  end

end

# vim: foldmethod=syntax
