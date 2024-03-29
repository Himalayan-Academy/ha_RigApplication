script "constructaudiodata"

global gRigA,gData
local sStackInUse

on libraryStack
  if (gRigA is not an array) and (the environment is "server") then
    put "No direct script access allowed."
    exit to top
  end if

  if the short name of the target = the short name of me then
    if sStackInUse <> TRUE then
      put TRUE into sStackInUse

      # LOGGING
      if the environment is "server" then
        rigLogMessage "debug", "Construct Audio Data Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


-------------------------- rabit
# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialConstructaudiodataConfig pConfig

end rigRunInitialConstructaudiodataConfig
------------------------


# LOGGING
-- rigLogMessage "debug", "Construct Audio Data library loaded" ---------- rabit

# DECLARE GLOBAL VARIABLES
global gData

# DECLARE LOCAL VARIABLES	
local tTranscript, tMusicInfo

# This library chooses data from audio for display to the user 
# based on audio type: one set of data for songs, transcripts for 
# inspired talks, different set of data for chants etc.

# html chunks should be semantically "pure"
# do not include any presentation mark up.
# just fill vars and then use wrappers and div classes
# in the view so that the CSS can do it's job depending
# on the distribution context (web page, mobile, iPhone, Tablets etc.)

# Description will be displayed for all media types:
# Just extend the gData array, use suffix "*Display" for key names

command buildAudioDataDisplay
	
# top level switch is by media type
# we only have two now: song and inspiredtalk... later we can add chant
# as a new case when we get that together.

switch gData["record"]["media_type"]

	case "audio/inspiredtalk"
	# All we need is the transcript
		if gData["record"]["audio_file_transcript"] <> empty then
			put ("<h3>Unedited Transcript: </h3><p>"&gData["record"]["audio_file_transcript"]&"</p>") into gData["transcriptDisplay"]
		end if
		break
		
	case "audio/song"
	
		if  gData["record"]["model_for_study"] ="YES" then
			put "<p>This melody is suggested as a model for global group learning.</p>" into  gData["modelDisplay"]
		end if
	
		put   "<li><b>Genre</b>: " &  gData["record"]["genre"] into tGenre 
		put   "<b>Deity</b>: "&  gData["record"]["deity"] &"</li>" into tDeity
		
		if  gData["record"]["source"] <> empty then
			put   ("<li><b>Source</b>: "& gData["record"]["source"]&"</li>") into tSource
		end if
		
		if  gData["record"]["artists"] <> empty then
			put   ("<li><b>Artists</b>: "& gData["record"]["artists"]&"</li>") into tArtists
		end if
	
		
		# The minimal music info would be the sruti or pitch of the sa/tonic note
		# of the raga/scale If this is present then we display a list item with 
		# all the music info
		
	   
	
		if  gData["record"]["ragam"] <> empty then
			put   ("Ragam-"&  gData["record"]["ragam"] ) into tRagam 
		end if
	
		if  gData["record"]["talam"] <> empty then
			put   (" | Talam-" &  gData["record"]["talam"] ) into tTalam 
		end if
		
		if   gData["record"]["sruti_tonic"] <> empty then  	
			put   (" | Sruti-"&  gData["record"]["sruti_tonic"] ) into tSruti
		end if
		
		if  gData["record"]["graha_note"] <> empty then
			put   (" | Graha-" &  gData["record"]["graha_note"] ) into tGraha
		end if
		
		put (tRagam & tTalam & tSruti & tGraha) into tMusicInfo
		
		if tMusicInfo <> empty then
			# we have data, wrap it in tags:
			put    format("<li id=\"music-info\" & ><b>Music Details:</b> ") before tMusicInfo  
			put   "</li>" after tMusicInfo
		end if
	
		  put (tGenre &&  tDeity & tSource & tArtists & tMusicInfo) into  gData["musicInfoDisplay"]
	   
	# lyrics are next, fetch data from the lyrics table 
	# based on the lyrics_id
	 if  gData["record"]["lyrics_id"] > 0 then
	   # assume we have lyrics in the lyrics table
	  
	   put gData["record"]["lyrics_id"] into tLyricsID
	  
		rigDbSelect "original_script,transliteration,diacritical_transliteration,literal_translation"
		rigDbWhere "lyrics_id", tLyricsID
		put rigDbGet("song_lyrics") into tLyricsQuery
		put rigDbRow(1) into tLyricsA
		
		if  tLyricsA["original_script"] <> empty then	 		
			put  ("<h3>Original Script</h3><p>"& tLyricsA["original_script"] &"</p>") after tLyrics
		end if

		if  tLyricsA["transliteration"] <> empty then
			put  ("<h3>Transliteration</h3><p>"& tLyricsA["transliteration"] &"</p>") after tLyrics
		end if
		
		if  tLyricsA["literal_translation"] <> empty then
			put  ("<h3>Translation</h3><p>"& tLyricsA["literal_translation"] &"</p>") after tLyrics
		end if
	
		replace cr with "<br/>" in tLyrics
		put tLyrics into  gData["lyricsDisplay"]

	end if
		
	
		 if ((gData["record"]["model_for_study"])= "Yes") and ( (gData["record"]["genre"])="natchintanai") then
	
		 put  format("<hr /><p><b>* Model for Study: </b>A major impediment to the spread of Natchintanai has been the diversity of melodies used for any given song. Hindu music is very creative and professionally trained Carnatic singers have a great deal of freedom for improvisation, much like modern western jazz musicians. But this leaves the average lay person with a big problem as well as teachers of groups or children when they come to learn the song. &quot;How should we sing it? What is the tune?&quot; To facilitate the dissemination of Yogaswami's songs the Swamis at Kauai Aadheenam have selected standardized tunes. Wherever possible we have tried to source these melodies from the Sri Lankan Jaffna community itself. Sometimes a complicated carnatic melody by a professional Jaffna Tamil singer has been simplified. (Gamakams are reduced for children) In cases where melodies are not known or are &quot;boring&quot; from a modern youth angle, we have adopted a more rhythmic, upbeat melody. We have to give credit to the Tiruvadi Niliyam (Jaffna Sai Baba devotees) who have sponsored some recordings by the All Ceylon Radio Singers for leading the way in this regard. These are good examples of Yogaswami's songs sung in a pleasing style. It is well known that Yogaswami himself did on occasion tell his devotees to sing such-and-such a Natchintanai song according to the melody of a song sung by one of the current popular devotional singers of his day. The melodies for many Natchintanai have yet to be selected for groups and children. If you would care to suggest some tunes we would very much appreciate your suggestions. Please email studyhall@hindu.org</p>") into gData["modelNoteDisplay"]
    end if
    
        

		break
end switch

    # Create Q & D download link using Andre's old library... I don't have time to figure out how he did it.
    # the code digging the format and the file path is in audio.lc but a bit over my head.
    # so for for now, just construct a "listen" URL

    put "/listen/" & gData["record"]["file_id"] & "/mp3"	 into gData["audioLinkPath"]
    
    
end buildAudioDataDisplay

--| END OF constructaudiodata.livecodescript
--| ./application/libraries/constructaudiodata.livecodescript
----------------------------------------------------------------------

