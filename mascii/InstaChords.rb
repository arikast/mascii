require 'mascii/Conveniences'

module Mascii
    #don't want any confusion with the chords used in mascii parsing grammar
	class InstaChords

	  attr_reader :maj, :min, :dim, :dom, :aug, :hdim, :fig

	  def initialize
		@chord_parser = Regexp.new(
			'([a-g][\+\-\=]*)(dom|dim|maj|min|m|hdim|aug|\:)?(([0-9]+[\+\-\=]*)*)((\/([0-9\<\>]*))?([a-g][\+\-\=]*)?)',
			Regexp::IGNORECASE)

	    #remember that fig bass is 1-based but arrays are 0-based
		@dom = JazzScale.new [2, 2, 1, 2, 2, 1, 2]
		@dim = JazzScale.new [2, 1, 2, 1, 2, 1, 3]
		@hdim = JazzScale.new [1, 2, 2, 1, 2, 2, 2]
		@maj = JazzScale.new [2, 2, 1, 2, 2, 2, 1]
		@min = JazzScale.new [2, 1, 2, 2, 1, 2, 2]
		@aug = JazzScale.new [2, 2, 2, 2, 2, 1, 1]

	  end

	  def get_pitches(notewiz, chord)
		data = @chord_parser.match chord.strip
		if data.nil? 
			return nil
		end

		root_note = data[1]
		chord_type = data[2]
		figures = data[3]
		boct_given = data[7]
		if boct_given != nil && boct_given.size == 0
			boct_given = nil
		end
		bass = data[8]
						
		case chord_type
			when 'dom'
				chart = dom
			when 'dim'
				chart = dim
			when 'hdim'
				chart = hdim
			when 'min'
				chart = min
			when 'maj'
				chart = maj
			when 'm'
				chart = min
			when 'aug'
				chart = aug
			else
				chart = dom			
		end
		
		@orig_octave = notewiz.octave
		#manually (and redundantly) apply any octave shifts (temporarily)
		#because the octave spec rule won't match til AFTER this instachord rule
		#so its effect is not seen inside this rule
		if boct_given != nil && bass != nil
			boct_given.each_char {|c|
				case c
					when '>'
						notewiz.octave_shift c
					when '<'
						notewiz.octave_shift c
					else
						notewiz.octave = c
				end					
			}
		end

		if ! bass.nil?
			bassnote = notewiz.letter_to_int bass
		else
			bassnote = nil
		end
		#when bassnote is provided, then that becomes anchor
		answer = chart.get_pitches notewiz.letter_to_int(root_note), figures, bassnote, ! bassnote.nil?
		#revert the temporary octave shift hack and return notewiz to its original state
		notewiz.octave = @orig_octave
		return answer
	  end
	  
	end

	#defines the intervals from root on this scale
	class Scale
		attr_accessor :intervals, :default_figs
		
		def initialize(steps = [], default_figs = [3,5])
			
			@fig_parser = Regexp.new('(1?[0-9])([\+\-\=]*)')
			@intervals = [0]
			total = 0
			0.upto(steps.size - 1) {|i|
				total += steps[i]
				@intervals << total
			}
			@default_figs = default_figs
		end
		
		#parses the figure numbers with their accidentals, and fills in default figures along the way
		def each_figure(figures, fillgaps)
		    #supports up to 19, so teen numbers need special parsing
		    figs = figures.scan @fig_parser
			figs.each {|f| f[0] = f[0].to_i }
			
			#fill in gaps by adding figures in increments of 2 counting down
			#except 6 and under.  So 9 becomes 97.  129 becomes 121097
			#5 and under is covered by the default figs
			if fillgaps
				orig = figs.map {|f| f[0]}
				filled = orig.dup
				
				suppress_default_figs = false
				orig.each {|f|
					if f < 6
						#writing a 2 or 4 supresses the default 3,5
						suppress_default_figs = true
					end
					
					filling = f
					while (filling -= 2) > 6 do
						if (filled.include? filling) || (filled.include?(filling + 1))
							break
						end
						filled << filling
						figs << [filling, '']
					end
				}
				unless suppress_default_figs
					default_figs.each {|f|
							unless (filled.include? f) 
								figs << [f, '']
							end					
					}
				end
			end
			
			#always return from highest to lowest
			#calling code currently relies on this
			figs.sort! {|a, b|
				b[0] <=> a[0]
			}
			figs.each {|f|
				yield f[0], f[1]
			}
		end
		
		def as_offset(fig, acc)
				f = fig - 1
				fnote = f % 7
				focts = (f / 7) * 12
				
				offset = intervals[fnote] + focts
				offset += NotationWiz.quantify_accidentals(acc)		
		end
		
		def already_there(arr, p)
			answer = false
			arr.each {|a|
				if NotationWiz.is_octave(a, p)
					answer = true
					break
				end
			}
			return answer
		end
	end

	class JazzScale < Scale
	    #normally bass shifts to accomodate the root pitch, but with anchorbass true
		#then the bass is fixed and root pitch shifts to accomodate
		def get_pitches(root_pitch, figures, bassnote, anchorbass)
			answer = []

			if ! bassnote.nil?
			    if anchorbass
					root_pitch = NotationWiz.nearest_pitch_above(bassnote, root_pitch)
					answer << bassnote
				elsif bassnote != root_pitch
					bassnote = NotationWiz.nearest_pitch_below(root_pitch, bassnote)
					answer << bassnote
				end
			end

			each_figure(figures, true) {|fig, acc|
				offset = as_offset(fig, acc)
				p = root_pitch + offset
				
				if bassnote.nil?
					unless offset < 12 && already_there(answer, p)
						answer << p
					end
				else
					if offset == 12 
						answer << p
					elsif offset > 12 && ! NotationWiz.is_octave(bassnote, p)
						answer << p
					elsif offset < 12 && ! NotationWiz.is_octave(bassnote, p)
					    #only add if not already there.  ie don't wanna add 3 if 10 already there
						#only applies to nums below 12 cuz small intervals sound esp bad doubled
						unless already_there(answer, p)
							answer << NotationWiz.nearest_pitch_above(bassnote, p)
						end
					end					
				end
			}
			
			answer << root_pitch
			
			return answer
		end
	end
	
	#will be used for figured bass
	class BaroqueScale < Scale
		def get_pitches(root_pitch, figures)
		
		end	
	end
end