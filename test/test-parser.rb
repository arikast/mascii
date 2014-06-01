ROOT_DIR = File.join(File.dirname(__FILE__), '..')
$:<< ROOT_DIR 

require 'treetop'
require 'test/unit'
require 'mascii/NotationWiz'
require 'mascii/MasciiNodes'
require 'mascii/MasciiContext'
require 'mascii/Instachords'
include Mascii


Treetop.load "#{ROOT_DIR}/mascii/mascii"

class MasciiParserTest < Test::Unit::TestCase
  
  def setup
    @parser = MasciiParser.new
  end
  
  def teardown
  end
  
  def test_basic
    assert @parser.parse('| a . ce d |')  
  end

  def test_accidentals
    assert @parser.parse('| a+ |')  
  end

  # note that octave parsing and shifting is done externally to letter_to_int method and is carried in the noteconverter state
  def test_octaves
    assert @parser.parse('| 4a . 3c2e- 3d+ |')  
    @noteconverter = NotationWiz.new
    assert_equal @noteconverter.letter_to_int('c'), 60
    assert_equal 60, @noteconverter.letter_to_int('4c')
    assert_equal 48, @noteconverter.letter_to_int('4C')
    @noteconverter.octave=3
    assert_equal 48, @noteconverter.letter_to_int('c')
    @noteconverter.octave=1
    assert_equal 24, @noteconverter.letter_to_int('c')
    #assert_equal 0, @noteconverter.letter_to_int('c-1')
  end

  def test_measures
    assert @parser.parse('| a . ce d | a f g | g g e f a |')  
  end

  def test_partial_measures
    assert @parser.parse('a b | a . ce d | a f g | g g e ')  
  end

  def test_elements
    assert @parser.parse('| a (bd . ce) cd (de f) |')
  end

  def test_nested_elements
    assert @parser.parse('| a (bd (c b) a) g ac |')
  end

  def test_meta_remarks
    assert @parser.parse('"h"| a (bd (c b) a) g ac |')
    assert @parser.parse('"hey there ari"| a (bd (c b) a) g ac |')
    assert @parser.parse('"whassup" a (bd (c b) a) g ac ')
  end

  def test_advanced_accidentals
    assert_equal 2, NotationWiz.quantify_accidentals('++')
    assert_equal -2, NotationWiz.quantify_accidentals('--')
    assert_equal -1, NotationWiz.quantify_accidentals('-')
  end
  
  def test_note_converter
    @noteconverter = NotationWiz.new
    assert_equal 61, @noteconverter.letter_to_int('c+')
    @noteconverter.octave=0
    assert_equal 14, @noteconverter.letter_to_int('c++')
    assert_equal 15, @noteconverter.letter_to_int('e-')
    @noteconverter.octave=3
    assert_equal 43, @noteconverter.letter_to_int('F++')
    assert_equal @noteconverter.letter_to_int('a+'), @noteconverter.letter_to_int('b-')
    @noteconverter.octave=0
    assert_equal 20, @noteconverter.letter_to_int('a-')
    assert_equal 19, @noteconverter.letter_to_int('a--')
    @noteconverter.octave=3
    assert_equal @noteconverter.letter_to_int('F++'), @noteconverter.letter_to_int('A--')
    #assert_equal @noteconverter.letter_to_int('+b3'), @noteconverter.letter_to_int('^c4')
    @noteconverter.octave=2
    assert_equal @noteconverter.letter_to_int('+g'), @noteconverter.letter_to_int('-a')
    @noteconverter.octave=9
    assert_equal 116, @noteconverter.letter_to_int('g+')
    @noteconverter.octave=0
    assert_equal 11, @noteconverter.letter_to_int('c-')
  end

  def test_note_converter_memory
    @noteconverter = NotationWiz.new
    assert_equal @noteconverter.letter_to_int('c+'), @noteconverter.letter_to_int('c4')

  end
  
  def test_pass_by_ref
    @noteconverter = NotationWiz.new
    a = 1
    @noteconverter.pass_by_ref_test(a)  
    assert_not_equal 2, a
    a = 1
    @noteconverter.pass_by_ref_test2(a)  
    assert_equal 1, a
  end
  
  def test_key_signatures
    @noteconverter = NotationWiz.new
    @noteconverter.octave=3
    assert_equal 59, @noteconverter.letter_to_int('b')    
    @noteconverter.key_signature.set_key 'fm'
    assert_equal 58, @noteconverter.letter_to_int('b')    
    assert_equal 59, @noteconverter.letter_to_int('b=')    
    assert_equal 59, @noteconverter.letter_to_int('b')  
    assert_equal 59, @noteconverter.letter_to_int('b=')  
    @noteconverter.key_signature.revert
    assert_equal 58, @noteconverter.letter_to_int('b')    
  end

  def test_instachords
    @noteconverter = NotationWiz.new
    ch = InstaChords.new
    puts ch.get_pitches(@noteconverter, "c765")
  end
end

