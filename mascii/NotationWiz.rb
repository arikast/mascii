require 'mascii/Conveniences'

module Mascii

class NotationWiz
  
  attr_accessor :key_signature, :transpose
  attr_reader :octave

  def initialize
    #@note_parser = Regexp.new('([+-=]*)([a-gA-G])([0-9]*)([<>]*)')
    @note_parser = Regexp.new('([a-gA-G])([\+\-\=]*)')
    @key_signature = KeySignature.new
    @octave = 4
	@transpose = 0
  end
  
  def octave=(oct)
		@octave = oct.to_i
  end
  
  def octave_shift(oct_sh)
	    @octave += NotationWiz.quantify_octave_shifts oct_sh
  end
  
  #converts 2c+ to its equiv midi pitch number
  #unless otherwise specified, scientific notation is used (not Helmholz)  
  def letter_to_int(noteletter)
    unless (data = @note_parser.match(noteletter.strip)).nil?

      accidentals = data[2] || ''
      
      #puts "data " , data.to_a
	  original_note = data[1]
      note = data[1].downcase
	        
      if accidentals.size == 0
        accidentals = key_signature.get_accidental note
      else
        key_signature.set_accidental note, accidentals
      end
      	  
      case note
            when 'c' 
                answer = 0
            when 'd' 
                answer = 2
            when 'e' 
                answer = 4
            when 'f' 
                answer = 5
            when 'g' 
                answer = 7
            when 'a' 
                answer = 9
            when 'b' 
                answer = 11
      end
            
      answer += 12 * (@octave + 1)
      answer += NotationWiz.quantify_accidentals accidentals
      
	  ### capital letters are played an octave lower than written
	  if note != original_note
	      answer -= 12
	  end
	  answer += @transpose
	  answer = NotationWiz.pitch_limits(answer)
      return answer
    else
      nil
    end
  end

  def NotationWiz.pitch_limits(answer)
      if answer > 127 
        answer = 108 + (answer % 12)
      end
      if answer < 0
        answer = 0 + (answer % 12)
      end  
	  return answer
  end
  
  def NotationWiz.is_octave(one, two)
	two % 12 == one % 12
  end
  
  def NotationWiz.nearest_pitch_above(threshold, pitch)
    toct = threshold / 12
	p = pitch % 12
	
	answer = (toct * 12) + p
	if answer <= threshold
		answer += 12
	end
	return NotationWiz.pitch_limits(answer)
	
  end  

  #if nothing found below then returns the lowest available
  def NotationWiz.nearest_pitch_below(threshold, pitch)
	
    toct = threshold / 12
	p = pitch % 12
	
	answer = (toct * 12) + p
	if answer >= threshold
		answer -= 12
	end
	return NotationWiz.pitch_limits(answer)
  end
  
  def NotationWiz.quantify_accidentals(a)
    answer = 0
    a.each_char { |c|
        case c
            when '+' 
                answer += 1
            when '-' 
                answer -= 1
        end
    }   
    answer        
  end

  def NotationWiz.quantify_octave_shifts(a)
    answer = 0
    a.each_char { |c|
        case c
            when '>', 'o'
                answer += 1
            when '<', 'O'
                answer -= 1
        end
    }   
    answer        
  end

  def debug_matches(matchdata)
    0.upto((matchdata.size) -1) {|i|
		puts "#{i} = #{matchdata[i]}"
    }
  end
  
  #answer: ruby is pass by ref.
  #assigning the passed-in var to something else doesn't affect the original var ref
  #on the caller's end
  def pass_by_ref_test (a)
    a = a + 1
    return a
  end

  def pass_by_ref_test2 (a)
    b = a 
    b = b + 1
    return a
  end
  
end

class KeySignature  
  @@C = {}  
  @@F = {'b' => '-'}
  @@B_FLAT = {'b' => '-', 'e' => '-'}  
  @@E_FLAT = {'b' => '-', 'e' => '-', 'a' => '-' }  
  @@A_FLAT = {'b' => '-', 'e' => '-', 'a' => '-', 'd' => '-' }  
  @@D_FLAT = {'b' => '-', 'e' => '-', 'a' => '-', 'd' => '-', 'g' => '-' }  
  @@G_FLAT = {'b' => '-', 'e' => '-', 'a' => '-', 'd' => '-', 'g' => '-' , 'c' => '-'}  
  @@C_FLAT = {'b' => '-', 'e' => '-', 'a' => '-', 'd' => '-', 'g' => '-' , 'c' => '-', 'f' => '-'}  

  @@G = {'f' => '+'}  
  @@D = {'f' => '+', 'c' => '+'}  
  @@A = {'f' => '+', 'c' => '+', 'g' => '+'}  
  @@E = {'f' => '+', 'c' => '+', 'g' => '+', 'd' => '+'}  
  @@B = {'f' => '+', 'c' => '+', 'g' => '+', 'd' => '+', 'a' => '+' }  
  @@F_SHARP = {'f' => '+', 'c' => '+', 'g' => '+', 'd' => '+', 'a' => '+' , 'e' => '+'}  
  @@C_SHARP = {'f' => '+', 'c' => '+', 'g' => '+', 'd' => '+', 'a' => '+' , 'e' => '+', 'b' => '+'}  
  
  attr_accessor :temp_key_signature
  attr_reader :key_signature, :is_minor 
  
  def initialize()
    @key_signature={}
    @temp_key_signature={}
    @is_minor = false
  end
  
  def key_signature=(k)
    @key_signature = k
    revert
  end

  def set_key(key_name)
    if key_name.nil?
        return false
    end
    
    k = key_name.upcase    
    case k
        when 'A'
            self.key_signature=@@A.deep_copy
        when 'A-'
            self.key_signature=@@A_FLAT.deep_copy
        when 'A+'
            self.key_signature=@@A_SHARP.deep_copy
        when 'B'
            self.key_signature=@@B.deep_copy
        when 'B-'
            self.key_signature=@@B_FLAT.deep_copy
        when 'C'
            self.key_signature=@@C.deep_copy
        when 'C-'
            self.key_signature=@@C_FLAT.deep_copy
        when 'C+'
            self.key_signature=@@C_SHARP.deep_copy
        when 'D'
            self.key_signature=@@D.deep_copy
        when 'D-'
            self.key_signature=@@D_FLAT.deep_copy
        when 'E'
            self.key_signature=@@E.deep_copy
        when 'E-'
            self.key_signature=@@E_FLAT.deep_copy
        when 'F'
            self.key_signature=@@F.deep_copy
        when 'F+'
            self.key_signature=@@F_SHARP.deep_copy
        when 'G'
            self.key_signature=@@G.deep_copy
        when 'G-'
            self.key_signature=@@G_FLAT.deep_copy
        when 'G+'
            self.key_signature=@@G_SHARP.deep_copy

        when 'AM'
            self.key_signature=@@C.deep_copy
        when 'A-M'
            self.key_signature=@@C_FLAT.deep_copy
        when 'A+M'
            self.key_signature=@@B_SHARP.deep_copy
        when 'BM'
            self.key_signature=@@D.deep_copy
        when 'B-M'
            self.key_signature=@@D_FLAT.deep_copy
        when 'CM'
            self.key_signature=@@E_FLAT.deep_copy
        when 'C+M'
            self.key_signature=@@E.deep_copy
        when 'DM'
            self.key_signature=@@F.deep_copy


        when 'D+M'
            self.key_signature=@@F_SHARP.deep_copy
        when 'EM'
            self.key_signature=@@G.deep_copy
        when 'E-M'
            self.key_signature=@@G_FLAT.deep_copy
        when 'FM'
            self.key_signature=@@A_FLAT.deep_copy
        when 'F+M'
            self.key_signature=@@A.deep_copy
        when 'GM'
            self.key_signature=@@B_FLAT.deep_copy
        when 'G+M'
            self.key_signature=@@B.deep_copy
    end
    if k =~ /M$/ 
        @is_minor = true
    end
  end
  
  def accidental_count
      NotationWiz.quantify_accidentals @key_signature.values.join('')
  end
  
  def adjust_key(note, accidental)
    @key_signature[note] = accidental
    set_accidental note, accidental
  end  

  def revert
    @temp_key_signature = @key_signature.deep_copy
  end

  def set_accidental(note, accidental)
    @temp_key_signature[note] = accidental
  end

  def get_accidental(note)
    @temp_key_signature[note] || ''
  end

end
end
