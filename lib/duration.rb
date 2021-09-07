
module Duration

  def self.parse duration
    #md = duration.match /\A(?:(?<hours>\d+)h)?\s*(?:(?<minutes>\d+)m)?\s*(?:(?<seconds>\d+(\.\d+)?)s)?\Z/i
    md = duration.match /\A
			  (?=\d+[hms])
			  (?<duration>
			    (?:(?<hours>\d+)h\s*)?
			    (?:(?<minutes>\d+)m\s*)?
			    (?:(?<seconds>\d+(\.\d+)?)s\s*)?
			  )
			  (?!\d+)
			\Z/ix
    raise "invalid duration format: #{duration}" unless md
    seconds_m = md[:seconds]
    seconds =  seconds_m.nil? ? 0 : (seconds_m.include?('.') ? seconds_m.to_f : seconds_m.to_i)
    seconds + 3600 * md[:hours].to_i + 60 * md[:minutes].to_i
  end

  def self.replace_expr_durations expr
    re = /\b
	    (?=\d+[hms])
            (?<duration>
	      (?:(?<hours>\d+)h\s*)?
	      (?:(?<minutes>\d+)m\s*)?
	      (?:(?<seconds>\d+(\.\d+)?)s\s*)?
	    )
	    (?!\d+)
	 \b/ix
    while md = expr.match(re)
      seconds_m = md[:seconds]
      seconds =  seconds_m.nil? ? 0 : (seconds_m.include?('.') ? seconds_m.to_f : seconds_m.to_i)
      seconds += 3600 * md[:hours].to_i + 60 * md[:minutes].to_i
      expr[md.begin(:duration)..md.end(:duration) - 1] = seconds.to_s
    end
    expr
  end

  def self.humanize_seconds seconds
    m1 = 60
    h1 = m1 * 60
    j1 = h1 * 24
    seconds = seconds.to_i
    jhms = [ seconds / j1, seconds % j1 / h1, seconds % h1 / m1, seconds % m1 ]
    units = %w{ j h m s }
    jhms = jhms.zip units
    jhms.delete_if { |v,u| v == 0 }
    if jhms.empty?
      '0s'
    else
      jhms.map { |v,u| v.to_s + u.to_s }.join(' ')
    end
  end

end

