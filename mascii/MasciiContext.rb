require 'mascii/Conveniences'

module Mascii
	class MasciiContext
	  attr_accessor :notewiz, :held_notes, :history, :midi_generator, :feel
	  attr_accessor :dotted_split, :reverse_dotted_split, :instachords
	  #insures no sound occurs before this tick count
	  attr_accessor :first_sound_delay
	  
	  def initialize()
		@notewiz = NotationWiz.new
		@held_notes = []
		@history = History.new
		@feel = 90
		@dotted_split = [75, 25]
		@reverse_dotted_split = [25, 75]
		@instachords = InstaChords.new
		@first_sound_delay = 0
	  end
	  
	  def adjust_for_feel(note_duration)
		  answer = ((self.feel/100.0)*note_duration).round
		  return answer
	  end	  
	end
	
	class History
		#a harmony may consist of several notes
		#harmonies are differentiated by their start times
		#history only remembers last harmony, but may go deeper in the future
		#might support a '' syntax to quote a harmonic sequence, then
		#x cycles through the harmonies defined in the sequence
		#later rhythmic history may be added
		
		def initialize()
			@mrh = [] #most recent harmony
			@mrst = -1 #most recent start time
		end	

		def register(start_time, note)
			if start_time < @mrst
				return
			end
			
			if start_time > @mrst
				@mrh = []
				@mrst = start_time
			end
			
			@mrh << note
		end
		
		def recall_harmony()
			return @mrh
		end
	end
end
