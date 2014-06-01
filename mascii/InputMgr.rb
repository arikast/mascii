require 'mascii/Conveniences'

module Mascii

class InputMgr
  attr_accessor :raw_data, :voice_lines
    
	def initialize()
		@voice_lines = []
		@meta_stripper = Regexp.new('"(([^"])*)"')
		@measure_splitter = Regexp.new('[\|]')
		@floating_octaves = Regexp.new('\s([0-9<>]+)\s')
		@illegal_chars = Regexp.new('([^\s0-9xXoO<>*\!\.a-g_A-G\~\(\)\[\]\{\}\+\-\=augdomihnjs\:\/]+)')
		
		@tab_len = 8
		@max_line_len = 96
		@contains_bar_lines = nil
	end
	
  def load_from_file(filepath)
	load_data(File.readlines(filepath))
  end

  def load_data(data)
    @raw_data = data
	join_voice_lines!
  end
  
  def inspect
    puts @raw_data  
	puts "converted to:"
	puts @voice_lines
  end

  def contains_bar_lines
      if @contains_bar_lines == nil
		spot_check()
	  end
	  puts "contains bar lines:#{@contains_bar_lines}"
	  return @contains_bar_lines
  end
  
  def spot_check()
  
    @voice_lines.each_index {|i|
		    line = @voice_lines[i]
			clean_line = line.gsub(@meta_stripper, '')
			@contains_bar_lines |= (clean_line =~ /\|/)

			split_line = clean_line.split(@measure_splitter)
			split_line.each_index {|m|
				measure = split_line[m]
	    
				warning ||= check_floating_octaves measure
				warning ||= check_illegal_chars measure
			    warning ||= check_nesting measure, '(', ')'
			    warning ||= check_nesting measure, '[', ']'
			    warning ||= check_nesting measure, '{', '}'		
				
				if warning
					return "Track #{i + 1}, measure #{m}: " + warning
				end
		    }
	}  
	return nil
  end


  def determine_time_sig
		@voice_lines.each {|line|
				metas = line.scan(@meta_stripper).join(' ')
				if metas
					InputMgr.split_tags(metas) {|key, value|
							if key == 'time'
							    return *(value.split('/').map {|s| s.to_i})
							end
					}
			    end
		}
		return 4, 4
  end

  def InputMgr.split_tags(content)
            tags = content.split(/\s|_/)
            tags.each {|tag|
                yield tag.split(/=|:/)
			}
  end

  def check_floating_octaves(text)
      if text =~ @floating_octaves
		return "octave designation '#{$1}' must come immediately next to an element, with no space in between"
	  end
  end

  def check_illegal_chars(text)
      if text =~ @illegal_chars
		return "Mascii does not allow these characters outside of comment lines or meta instructions: '#{$1}'"
	  end
  end
  
  def check_nesting(text, openchar, closechar)
      depth = 0
	  text.each_char {|c|
		if c == openchar
		    depth += 1
		elsif c == closechar
		    depth -= 1
		end
		
		if depth < 0
		    return "#{closechar} came before #{openchar}. Each #{closechar} must be preceded by a matching #{openchar} in the same measure"
		end
      }
	  if depth > 0
	      return "each #{openchar} must be matched by a #{closechar} within the same measure"
	  end
	  return nil
  end

  def remove_double_barlines
    @voice_lines.each_index {|i|
		    line = @voice_lines[i]
			@voice_lines[i] = line.gsub(/[\|]\s*([\|]\s*)*[\|]/, '|')
	}
  end


### "beautify layout" feature to line up measures
###  algorithm: convert all spaces to single space, then calc length and pad w tabs
###  so lines match up.  make tab size and max line length variables so it can be customized.
###  will attempt to fit 2 lines per stave, and will space divider down middle when possible
  def beautified_layout
  
  end

private
  def join_voice_lines!
	index = 0
    comment_re = Regexp.new(/^\s*#/)    
    blank_re = Regexp.new(/^\s*$/)

    @raw_data.each {|line|
		line.chomp!
	    #line.rstrip!
	
	    #strip out comments
		if line =~ comment_re		
			next
		end
			
		if line =~ blank_re
		    index = 0
		else		    
		    if @voice_lines[index] 
			    @voice_lines[index] << ' '
			    @voice_lines[index] << line
	        else
			    @voice_lines[index] = line
			end
			index += 1
		end
    }
	
	remove_double_barlines
  end

  #quicktime in web browser makes this horrible "glitch" sound when notes occur
  #before it's ready... a little pause at the start solves it
  def prepend_empty_measure
	@voice_lines.each_index {|i|
		@voice_lines[i].insert(0, ' . | ')
		puts @voice_lines[i]
	}
  end
  
#####################################################################
###### SPECIAL CASE: to adding an intermittant extra voice like this:
###### | a b a b | a b a b |
###### 
###### | a b a b | a b a b |
###### | c d c d |
###### 
###### Compiler can't calculate where you've put it visually, so 
###### therefore extra voice lines must come directly after a staff line break
###### 
  
end

end
