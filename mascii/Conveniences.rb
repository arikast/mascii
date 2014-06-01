require 'midilib/sequence'
require 'midilib/consts'

class Object::String
  #def each_char()
    #each_byte {|b|
        #yield b.chr
    #}
  #end
  
  def smart_slice(from, to)
	from = Math.to_i_limit(from, 0, to)
	to = Math.to_i_limit(to, from, self.length)
	self[from ... to]
  end
end

class Object::Hash
  def deep_copy
      answer = {}
      self.each {|k, v|
          answer[k] = v    
      }
      answer
  end
end

#module Mascii

class MIDI::Track
  attr_accessor :mascii_midi_channel
end

#class MIDI::KeySig
	
    #def data_as_bytes
        #data = ''
		#data << @status
		#data << @meta_type
		#data << 2
		#acc_count = @data[0]
		
		##neg values (representing flat keys) need to be specially squeezed 
		##into a single byte using 2's compliment logic
		#if acc_count < 0
		  #data << (256 - acc_count.abs)
		#else
		  #data << acc_count
		#end

        #data << (@data[1] ? 1 : 0)
    #end
	
#end

#end #module Mascii

module Math

	def Math.to_i_limit (str, lower, upper)        
		answer = str.to_i
		if answer > upper
		  return upper 
		elsif answer < lower
		  return lower 
		end            
		answer
	end
end
