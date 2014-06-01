$:<< File.join(File.dirname(__FILE__), '..')
require 'midilib/sequence'
require 'midilib/consts'
include MIDI
require 'mascii/Conveniences'


# p MIDI::Tempo::MICROSECS_PER_MINUTE

seq = Sequence.new()


# Create a first track for the sequence. This holds tempo events and stuff
# like that.
track = Track.new(seq)
track.events << Tempo.new(Tempo.bpm_to_mpq(120))
track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')

# Create a track to hold the notes. Add it to the sequence.
track = Track.new(seq)
track.name = 'Main Track'
track.instrument = GM_PATCH_NAMES[0]

# Add a volume controller event (optional).
track.events << Controller.new(0, CC_VOLUME, 127)

# Add events to the track: a major scale. Arguments for note on and note off
# constructors are channel, note, velocity, and delta_time. Channel numbers
# start at zero. We use the new Sequence#note_to_delta method to get the
# delta time length of a single quarter note.
track.events << ProgramChange.new(0, 1, 0)
quarter_note_length = seq.note_to_delta('quarter')

#quarter note is always 480
#therefore full measure always contains 4x = 1920
#setting start_time lets you control absolute times

start_time = quarter_note_length

treble = [0, 2, 4, 5, 2, 4, 0, 7]

treble.each { | offset |
  note_on = NoteOnEvent.new(0, 64 + offset, 127, 0)
  note_on.time_from_start = start_time
  #note_on.time_from_start = 480
  #puts note_on.time_from_start
  track.events << note_on
  start_time += quarter_note_length
  #puts note_on.time_from_start
}

start_time = quarter_note_length * 2
treble.each { | offset |
  #note_on.time_from_start = 480
  note_off = NoteOffEvent.new(0, 64 + offset, 127, 0)
  note_off.time_from_start = start_time
  #puts note_on.time_from_start
  track.events << note_off 
  start_time += quarter_note_length

  #puts note_on.time_from_start
}

### bass line
bass = [7, 12, 11, 12]

start_time = 0
bass.each { | offset |
  note_on = NoteOnEvent.new(0, 52 + offset, 127, 0)
  note_on.time_from_start = start_time
  #note_on.time_from_start = 480
  #puts note_on.time_from_start
  track.events << note_on
  start_time += quarter_note_length * 2

  #puts note_on.time_from_start
}

start_time = quarter_note_length * 2
bass.each { | offset |
  note_off = NoteOffEvent.new(0, 52 + offset, 127, 60)
  note_off.time_from_start = start_time - 4
  #note_on.time_from_start = 480
  #puts note_on.time_from_start
  track.events << note_off
  start_time += quarter_note_length * 2

  #puts note_on.time_from_start
}


track.sort

# Calling recalc_times is not necessary, because that only sets the events'
# start times, which are not written out to the MIDI file. The delta times are
# what get written out.

# track.recalc_times

File.open('test2.mid', 'wb') { | file |
	seq.write(file)
}

