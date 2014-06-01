$:<< File.join(File.dirname(__FILE__), '..')

require 'treetop'
require 'mascii/MasciiNodes'
require "mascii/EZMidiGen"
require "mascii/MasciiContext"
require "mascii/InputMgr"
require "mascii/VoiceAssembly"
include Mascii

## to regenerate treetop parser do this:
## cd mascii; tt mascii.treetop

args = ARGV
if args.length == 0
    args << 'music-samples/cantata_ari.txt'
    args << 'music-samples/chopin-etude.txt'
    args << 'music-samples/raindrop-prelude.txt'
    args << 'music-samples/mozart-3on4.txt'
    args << 'music-samples/impromptu.txt'
    args << 'music-samples/rhythm.txt'
    args << 'music-samples/dotted_rhythms.txt'
    args << 'music-samples/waltz.txt'
    args << 'music-samples/jazz_licks.txt'
    args << 'music-samples/pharcyde.txt'
    args << 'music-samples/testing.txt'
    args << 'music-samples/drum_sampler.txt'

end

args.each {|file|
    puts "--- parsing #{file} ---"	
	input = InputMgr.new
	input.load_from_file file
	#input.join_voice_lines!

	if ((problem = input.spot_check) != nil)
		puts problem
		exit
	end

	assembler = VoiceAssembly.new 
	midiGen = assembler.assemble(input)
	if ! assembler.message.nil?
		puts assembler.message
	end
	
	outpath = "#{file}.mid"
	midiGen.dump_midi_file outpath
}

