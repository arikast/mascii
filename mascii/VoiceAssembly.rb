require 'treetop'

require 'mascii/Conveniences'
require 'mascii/EZMidiGen'
require 'mascii/MasciiContext'
require 'mascii/InputMgr'
require 'mascii/InstaChords'
#require 'mascii/MasciiParser'
require 'mascii/mascii'

module Mascii
	class VoiceAssembly
		attr_accessor :message
	
		def assemble(input, pad_measure = false)
			parser = MasciiParser.new

			num, denom = input.determine_time_sig
			ticks = EZMidiGen.calculate_ticks_per_measure num, denom
			if ! input.contains_bar_lines
			  parser.root = 'free_form'
			  ticks = ticks/4
			end
			#parser = Treetop.load "mascii/mascii"

			midiGen = EZMidiGen.new

			input.voice_lines.each {|line|
				tree = parser.parse(line)
				if tree.nil?		
					#parser.consume_all_input=false
					ind = parser.failure_index										
					self.message = "Could not understand '#{line.smart_slice(ind-1, ind+1)}'" +
						" near '#{line.smart_slice(ind-12, ind+12)}'"
					return nil
				end

				context = MasciiContext.new
				context.midi_generator = midiGen
				#context.first_sound_delay = first_delay
				if pad_measure
					tree.propagate_timings context, ticks, ticks
				else
					tree.propagate_timings context, 0, ticks
				end
				track = midiGen.make_track()
				tree.add_midi_events context, track
			}
			return midiGen
		end
	end
end
