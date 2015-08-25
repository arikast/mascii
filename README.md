########### what is this thing?
This is an implementation of the Mascii text-based music notation standard (see mascii.org).  This particular implementation reads mascii and outputs midi, thus it is a mascii-to-midi conversion engine.

########### setup instructions
1. install Ruby 2.0 or higher if you don't already have it
    1a. install the RVM ruby management system
    1b. use RVM to install ruby 2.0
2. gem install treetop
3. gem install midilib

########## how to generate a song
NOTE: this discusses how to generate midi files locally on your computer.  As an alternative, you'll also soon be able to use the upcoming online services which will be available at mascii.org.

1. Read about mascii syntax in the documentation/ dir or online at mascii.org.  Mascii is a general-purpose music data format designed to be easy to read and type with an ordinary computer.  It is free and open source, and comes distributed with a cross-platform engine which can convert mascii music into midi, for easy audio playback on your computer
2. Write your mascii music in a text file and save it.  There are samples to get you started in the music-samples directory.
3. If you saved your music in a file called "mysong.txt" in the current directory, then invoke the mascii engine like this:
    ruby bin/parser.rb mysong.txt
4. This will generate a midi file in the same directory called mysong.txt.mid
5. Now that you have a midi file, it is up to you to play it.  Midi files be played a variety of ways depending on your OS:  

    In Windows:
        you can generally double click it from explorer.  

    On a Mac:
        The latest version of Quicktime has "forgotten" how to play midi, so you can downgrade your quicktime to 7.x which is available from Apple.  
        Otherwise Garage Band can perhaps play it, or last resort the free open source program MuseScore can definitely play midi files.
    
    On Linux: 
        You can use timidity, which works OK but is missing many of the sound patches so you'll have to choose your instruments carefully.  
        PLEASE NOTE: a lot of free midi players are missing many sounds from their sound banks.  If you playback a midi file on one of these players, you won't hear those tracks.  
        Dont blame Mascii, blame your midi playback software!
 
    On BSD:
        I don't know, never tried running it there, but I'm sure there's a way 

########## technical lay of the land
All the meat n potatoes of the mascii engine are in the mascii/ directory.  Here's a tour of some important files there:

--- mascii.treetop 
This implementation of the mascii format uses a Ruby parser lib called TreeTop.  The treetop grammar is contained in mascii.treetop. The treetop grammar file can either be used directly, as seen in test/test-parser.rb, or for performance it can be pre-parsed into ruby files and subsequently used indirectly, as seen in bin/parser.rb.

To reparse the treetop file, issue this command from within the mascii/ directory to generate the file mascii.rb:
    tt mascii.treetop

This lets you change the grammar of mascii itself if you so desire.

--- mascii.rb
The expanded ruby equivalent of the grammar expressed in mascii.treetop.  To generate it, see instructions under the mascii.treetop section of this document

--- Conveniences.rb
Any core overrides or class tweaks go here.


######## running tests:
ruby test-parser.rb
ruby parser.rb
cd bin; ./generate-samples.sh

######## License:
The Mascii notation standard as well as this particular implementation of that standard were created by Ari Kast at kastkode.com.  It was originally created and made publically available in 2009, but I didn't get around to releasing the source code until 2014.  Sorry for the long delay, life got in the way (well if you call wage-slavery living).

This particular implmenetation of the Mascii standard is released under an MIT open source license.  In other words, do what you want with it, just add me in the credits.

