require 'treetop'
require 'midilib/sequence'
require 'midilib/consts'
include MIDI

require 'mascii/Conveniences'
require 'mascii/NotationWiz'
require 'mascii/InputMgr'

module Mascii

    class Treetop::Runtime::SyntaxNode
		
        def no_inspect()
           puts "#{self.class} - #{text_value}"
           if(elements) 
             elements.each {|e|
                e.inspect
             }
           end
        end
                

        def propagate_timings(context, time_start, time_length)
            propagate_unchanged(context, time_start, time_length)
        end

        #divides beat evenly among elements
        def split_beat(context, time_start, time_length, units)
		    #puts "even at " + text_value
            if elements && (units > 0)
                slice = time_length / units
                
                elements.each {|e|
                    e.propagate_timings context, time_start, slice
                    time_start += slice
                }     
            end
        end

        def split_beat_dotted(context, time_start, time_length, units)
			split_beat_custom(context, time_start, time_length, units, context.dotted_split)
		end
		
        #works like split_beat_dotted but defaults to 25 75, 25 75 instead.
		#can also be customized
        def split_beat_reverse_dotted(context, time_start, time_length, units)
			split_beat_custom(context, time_start, time_length, units, context.reverse_dotted_split)
        end

        #ratios is an array containing the time alottment ratios
		#eg 75, 25
		#or 25, 50, 25
        def split_beat_custom(context, time_start, time_length, units, ratios)
		    ratio_total = ratios.inject() {|result, num| result + num}.to_f

			even_slice = time_length / units
			custom_slices = ratios.map{|num|
				((num.to_f / ratio_total) * (ratios.size * even_slice)).to_i
			}
									
		    #puts "dotted at " + text_value
			remainder = elements.size % ratios.size			
			grouped_element_count = elements.size - remainder
			
			0.upto(grouped_element_count - 1) {|i|
				slice = custom_slices[i % custom_slices.size]				
				elements[i].propagate_timings context, time_start, slice
				time_start += slice
			}
			
			grouped_element_count.upto(elements.size - 1) {|j|
				slice = even_slice
				elements[j].propagate_timings context, time_start, slice
				time_start += slice				
			}
        end

        def propagate_unchanged(context, time_start, time_length)
            
            if elements && elements.size > 0
                slice = time_length
                
                elements.each {|e|
                    e.propagate_timings context, time_start, slice
                }     
            end  
        end

        def split_measures(context, time_start, time_length)
            if elements && elements.size > 0
                slice = time_length
                
                elements.each {|e| 
                    e.propagate_timings context, time_start, slice
                    time_start += slice
                }     
            end  
        end


        def add_midi_events(context, track)
            add_my_midi_events context, track
            add_midi_events_to_kids context, track
        end

        def add_my_midi_events(context, track)

        end

        def add_midi_events_to_kids(context, track)
            if elements
                elements.each {|e|
                    e.add_midi_events context, track
                }     
            end  
        end

    end

    class EvenCompositeNode < Treetop::Runtime::SyntaxNode
	end

    class DottedCompositeNode < Treetop::Runtime::SyntaxNode
	end

    class ReverseDottedCompositeNode < Treetop::Runtime::SyntaxNode
	end

    class BarlineNode < Treetop::Runtime::SyntaxNode

        def add_my_midi_events(context, track)            
            context.notewiz.key_signature.revert
        end
    end


    class ChordNode < Treetop::Runtime::SyntaxNode

        def propagate_timings(context, time_start, time_length)
            propagate_unchanged(context, time_start, time_length)
        end    

    end

    class InstaChordNode < Treetop::Runtime::SyntaxNode

        def propagate_timings(context, time_start, time_length)
            @time_start = time_start
            @time_length = time_length

			if @time_start < context.first_sound_delay
				@time_start = context.first_sound_delay
				@time_length -= context.first_sound_delay
			end
        end

        def add_my_midi_events(context, track)            
			harmony = context.instachords.get_pitches(context.notewiz, text_value)

			#harmony is a mechanism to piece together chords (ie multiple notes sounding at same time)
			#for the purpose of allowing x to repeat the harmony
			#aside from the special 'x' case, harmony will always have just one note in it
			#even in the case of a chord -- the notes are still defined individually
			harmony.each {|pitch|
				context.history.register(@time_start, pitch)
				note_on = NoteOnEvent.new track.mascii_midi_channel, pitch
				note_on.time_from_start = @time_start
				track.events << note_on


				#automatically add off value 
				#unless this note is already being held 
				#(don't wanna truncate the held note)            
				if context.held_notes.include? pitch
					special_prep_for_note_restrike context, track, pitch
				else
					note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
					note_off.time_from_start = (@time_start + context.adjust_for_feel(@time_length))
					track.events << note_off
				end
			}
        end
        
        #midi doesn't sound when already on note is struck again
        #so we give an off signal a split second before
        #and then restrike the sustained note
        def special_prep_for_note_restrike(context, track, pitch)
                note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
                note_off.time_from_start = @time_start - 5
                track.events << note_off                        
        end
        
    end




    class InstaChordStartNode < InstaChordNode
        def add_my_midi_events(context, track)
			text_v = text_value.delete('!')
			harmony = context.instachords.get_pitches(context.notewiz, text_v)
			
			harmony.each {|pitch|
				context.history.register(@time_start, pitch)
				if context.held_notes.include? pitch
					special_prep_for_note_restrike context, track, pitch
				end
				
				context.held_notes << pitch
				context.held_notes.uniq!
				
				note_on = NoteOnEvent.new track.mascii_midi_channel, pitch
				note_on.time_from_start = @time_start
				track.events << note_on
			}
        end
    end

    class InstaChordEndNode < InstaChordNode
        def add_my_midi_events(context, track)
        
			text_v = text_value.delete('*')
			pitches = context.instachords.get_pitches(context.notewiz, text_v)
            
            pitches.each {|pitch|                                
                note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
                note_off.time_from_start = (@time_start + context.adjust_for_feel(@time_length))
                track.events << note_off
                context.held_notes.delete(pitch)
            }
        end
    end





    class NoteNode < Treetop::Runtime::SyntaxNode

        def propagate_timings(context, time_start, time_length)
            @time_start = time_start
            @time_length = time_length
			
			if @time_start < context.first_sound_delay
				@time_start = context.first_sound_delay
				@time_length -= context.first_sound_delay
			end
        end

        def add_my_midi_events(context, track)            
			if text_value == 'x' || text_value == 'X'
				harmony = context.history.recall_harmony
				if harmony.nil? || harmony.length == 0
					return
				end
			else
			    harmony = []
				harmony << context.notewiz.letter_to_int(text_value)
				context.history.register(@time_start, harmony[0])
            end

			#harmony is a mechanism to piece together chords (ie multiple notes sounding at same time)
			#for the purpose of allowing x to repeat the harmony
			#aside from the special 'x' case, harmony will always have just one note in it
			#even in the case of a chord -- the notes are still defined individually
			harmony.each {|pitch|
				note_on = NoteOnEvent.new track.mascii_midi_channel, pitch
				note_on.time_from_start = @time_start
				track.events << note_on

				#automatically add off value 
				#unless this note is already being held 
				#(don't wanna truncate the held note)            
				if context.held_notes.include? pitch
					special_prep_for_note_restrike context, track, pitch
				else
					note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
					note_off.time_from_start = (@time_start + context.adjust_for_feel(@time_length))
					track.events << note_off
				end
			}
        end
        
        #midi doesn't sound when already on note is struck again
        #so we give an off signal a split second before
        #and then restrike the sustained note
        def special_prep_for_note_restrike(context, track, pitch)
                note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
                note_off.time_from_start = @time_start - 5
                track.events << note_off                        
        end
        
    end

    class NoteStartNode < NoteNode
        def add_my_midi_events(context, track)
			text_v = text_value.delete('!')
			if text_v == 'x' || text_v == 'X'
				harmony = context.history.recall_harmony
				if harmony.nil? || harmony.length == 0
					return
				end
			else
			    harmony = []
				harmony << context.notewiz.letter_to_int(text_v)
				context.history.register(@time_start, harmony[0])
			end
			harmony.each {|pitch|
				if context.held_notes.include? pitch
					special_prep_for_note_restrike context, track, pitch
				end
				
				context.held_notes << pitch
				context.held_notes.uniq!
				
				note_on = NoteOnEvent.new track.mascii_midi_channel, pitch
				note_on.time_from_start = @time_start
				track.events << note_on
			}
        end
    end

    class NoteEndNode < NoteNode
        def add_my_midi_events(context, track)
        
            #a lone * indicates all held notes should turn off
            if text_value.size == 1
				pitches = context.held_notes.dup
            else
				pitches = []
				text_v = text_value.delete('*')
				if text_v == 'x' || text_v == 'X'
					pitches = context.history.recall_harmony
				else
					pitches << context.notewiz.letter_to_int(text_v)              
				end
            end
            
            pitches.each {|pitch|                                
                note_off = NoteOffEvent.new track.mascii_midi_channel, pitch
                note_off.time_from_start = (@time_start + context.adjust_for_feel(@time_length))
                track.events << note_off
                context.held_notes.delete(pitch)
            }
        end
    end

    class OctaveNode < Treetop::Runtime::SyntaxNode
        def add_my_midi_events(context, track)
			context.notewiz.octave = text_value
		end
	
	end

    class OctaveShiftNode < Treetop::Runtime::SyntaxNode
        def add_my_midi_events(context, track)
			context.notewiz.octave_shift text_value
		end
	end
    
    class MetaRemarkNode < Treetop::Runtime::SyntaxNode
		def parse_timing_split(v)
			answer = v.split(/\//)
			answer.delete_if {|ru|
				ru.nil? || ru == 0 || ru == '0'
			}
			answer.map! {|ru|
					ru.to_i
			}
			return answer
		end

        def propagate_timings(context, time_start, time_length)
            @time_start = time_start
            @time_length = time_length
			
			content = text_value || ''
            if content.size == 0 
                return
            end
            
			InputMgr.split_tags(content) {|k, v|                
                case k 
				    when '[]'
						context.dotted_split = parse_timing_split(v)
				    when '{}'
						context.reverse_dotted_split = parse_timing_split(v)
				end
			}
        end
        
        def add_my_midi_events(context, track)
            content = text_value || ''
            if content.size == 0 
                return
            end
            
			InputMgr.split_tags(content) {|k, v|
                
                case k 
				    when 'transpose', 'tr'
						context.notewiz.transpose = Math.to_i_limit(v, -12, 12)
				    when 'time'
						num,denom = v.split(/\//)
                        context.midi_generator.time_sig_change(
                            @time_start, num.to_i, denom.to_i
                        )
					when 'channel', 'ch'
						track.mascii_midi_channel = (Math.to_i_limit v, 1, 16) - 1
                    when 'feel'
                        feel = Math.to_i_limit v, 10, 100
                        context.feel = feel
                    when 'tempo'
                        tempo = Math.to_i_limit v, 20, 300 
                        context.midi_generator.tempo_change @time_start, tempo
                    when 'instrument', 'instr', 'voice', 'vc'
                        instr = Math.to_i_limit v, 1, 128 
                        context.midi_generator.voice_change @time_start, track, (instr - 1)
                    when 'volume', 'vol'
                        puts "setting volume to #{v}"
                        volume = Math.to_i_limit v, 0, 127
                        context.midi_generator.volume_change @time_start, track, volume
                    when 'key'
                        context.notewiz.key_signature.set_key v
                        
                        context.midi_generator.key_sig_change(
                            @time_start,                             
                            context.notewiz.key_signature.accidental_count,
                            context.notewiz.key_signature.is_minor
                        )
                    when 'manualkey', 'mankey'
                        result = v.scan( (Regexp.new '([a-gA-G])(\+|-)*'))
                        if ! result.nil?
                          result.each {|r|
                              note, accidental = r[0..1]
                              context.notewiz.key_signature.adjust_key note, accidental                            
                          }
                        end
                end
            }
        end
    end

end
