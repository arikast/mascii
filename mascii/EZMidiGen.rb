require 'midilib/sequence'
require 'midilib/consts'
include MIDI
require 'mascii/Conveniences'

module Mascii

### tracks are a software construct.  everything must eventually funnel down to 
### 16 channels, which are the hard limit imposed by MIDI itself.
class EZMidiGen
	# These constants, for some reason, are missing from midilib
	CC_BANK_SELECT_COURSE = 0
	CC_BANK_SELECT_FINE = 32 
	CC_DATA_ENTRY_LSB = 38
	CC_ALL_CONTROLLERS_OFF = 121

  def initialize
    @curr_channel_index = -1	
	@channels = (0..8).to_a
	@channels += (10.. 15).to_a

    @seq = Sequence.new()
    #track 0 is for meta events (tempo, key signature)
    track = make_track()
    #track.events << Tempo.new(Tempo.bpm_to_mpq(120))
    track.events << MetaEvent.new(META_SEQ_NAME, 'Mascii Music')
    @curr_channel_index = -1
  end
  
  #never returns channel 9, the drum track
  def next_channel    
	 @curr_channel_index += 1
	 @curr_channel_index = @curr_channel_index % 15
	 return @channels[@curr_channel_index]
  end
  
  ################# META EVENTS ########################
  def tempo_change(start_time, tempo)
      event = Tempo.new(Tempo.bpm_to_mpq(tempo))
      event.time_from_start = start_time
      @seq.tracks[0].events << event
  end

  # 0..7 = sharps. -1..-7 = flats
  def key_sig_change(start_time, accidental_count, is_minor)
      event = KeySig.new(accidental_count, is_minor)
      event.time_from_start = start_time
      @seq.tracks[0].events << event
  end

  #denom is power of 2, so 6/8 time becomes 6, 3 (cuz 2 to 3 power = 8)
  #method returns number of ticks in measure
  #where quarter note = 480
  def time_sig_change(start_time, numerator, denominator)	  	  
	  case denominator
		when 1
			denom = 0
		when 2
			denom = 1
		when 4
		    denom = 2		
		when 8
			denom = 3
		when 16
			denom = 4
		when 32
			denom = 5
		else
			denom = 2
	  end
	  
      event = TimeSig.new(numerator, denom, 24, 8)
      event.time_from_start = start_time
      @seq.tracks[0].events << event
  end

  def EZMidiGen.calculate_ticks_per_measure(numerator, denominator)
	  if (numerator > 0) && ([1, 2, 4, 8, 16, 32].include? denominator)
		answer = numerator * 1920 / denominator		
	  end
	  answer ||= 1920
	  return answer
  end
  ################# CHANNEL EVENTS ########################
  
  def make_track()  
    track = Track.new(@seq)
	track.mascii_midi_channel = next_channel
    puts "making track #{track.mascii_midi_channel}"
    @seq.tracks << track

	#event = Controller.new(track.mascii_midi_channel, CC_ALL_CONTROLLERS_OFF, 0)
    #event.time_from_start = 0
	#track.events << event


    return track
  end
  
  def set_reasonable_defaults(track)
      #track.name = 'Main Track'
      #track.instrument = GM_PATCH_NAMES[0]
      #voice_change(1, track, 1)
      #volume_change(1, track, 127)
  end

  def voice_change(start_time, track, instr)
      event = ProgramChange.new(track.mascii_midi_channel, instr)
      event.time_from_start = start_time
      track.events << event
  end
  
  def volume_change(start_time, track, volume)
      event = Controller.new(track.mascii_midi_channel, CC_VOLUME, volume)
      event.time_from_start = start_time
      track.events << event      
  end
  
  def dump_midi_file(filename)
    File.open(filename, 'wb') { | file |
        dump_midi(file)
    }
  end

  def dump_midi(io_stream)
    @seq.tracks[0..@seq.tracks.size].each {|t|
        t.sort    
        #t.recalc_delta_from_times
    }
    
	@seq.write(io_stream)
  end
  
end

end
