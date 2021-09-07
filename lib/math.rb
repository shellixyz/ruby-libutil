
require 'prime'

class Array

    def mult
        reduce(1) { |acc, n| acc * n }
    end

end

class Integer

    def factors
        prime_division.flat_map { |n, nn| [n] * nn }
    end

    def divisors
        fs = factors
        (1...fs.length).flat_map { |n| fs.combination(n).to_a.map &:mult }.uniq.sort
    end

end
