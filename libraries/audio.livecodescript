script "audio"

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
        rigLogMessage "debug", "Audio Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ----------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "Audio Library Loaded" -------------- rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialaudioConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialaudioConfig


function findAudioByArray pA
	rigDbWhere pA
	combine pA by "," and "="
	rigLogMessage "debug", "looking for audio:" && pA
	put rigDbGet("item") into tQuery
	if tQuery["numrows"] > 0 then
		repeat with x = 1 to tQuery["numrows"]
			put rigDbRow(x) into tRetA[x]
			-- get the channels of distribution (mainly print version)
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("channel") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["channels"][y]
				end repeat
			end if
			-- get the available formats
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("item_format") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["formats"][y]
				end repeat
			end if
			-- go back to the book query
			put rigDbGet("item") into tQuery
		end repeat
	  return tRetA
	else
		return false
	end if
end findAudioByArray

function folderForAudio pA
	switch pA["media_type"]
		case "audio/song"
			# Songs folder structure is
			# /songs/<genre>/<deity>/
			put "songs" into tType
			put "/" & pA["genre"] after tType
			## Audio folders need more options depending on their genre.
			switch pA["genre"]
				case "bhajan"
				case "Bhakti-Gitam"
					put "/" & toLower(pA["deity"])  after tType
				break
			end switch
		break
		case "audio/chant"
			put "chants" into tType
		break
		case "audio/inspiredtalk"
			# Inspired talks folder structure is:
			# /inspired-talks/bodhinatha/
			# or
			# /inspired-talks/gurudeva/
			#
			put "inspired-talks" into tType
			set the itemdel to "-"
			put item 1 of pA["date_created"] into tYear 


		switch 
			case ("bodhinatha" is in pA["author"])
				put "/bodhinatha/" & tYear after tType
			    break
		    case ("sadasivanatha" is in pA["author"])
				put "/sadasivanatha/" & tYear after tType
			    break
			case ("sivaya" is in pA["author"])
				put "/gurudeva/" & tYear after tType
			    break
		end switch
		
			-- if "bodhinatha" is in pA["author"] then
			-- 	put "/bodhinatha/" & tYear after tType
			-- else
			-- 	put "/gurudeva/" & tYear after tType 
			-- end if
		break
		case "audio/podcasts"
			put "podcasts" into tType
		break
		case "audio/instrumental"
			put "instrumental" into tType
		break
		case "audio/shum"
			put "shum" into tType
		break
		case "audio/book"
			put "books" into tType
		break
	end switch	
	return ($_SERVER["DOCUMENT_ROOT"] & "/media/audio/" & tType &"/"& pA["file_id"]) 
end folderForAudio

function getAudioFormat pA
	if char 1 pA["formats"][1]["format_name"] <> "m"  then #now mp3,m4a
		return empty
	else
		--rigLogMessage "HI", pA["formats"][1]["format_name"] 
		return pA["formats"][1]		
	end if
end getAudioFormat

function getAudioMime pA 
	switch pA["formats"][1]["format_name"]
		case "mp3"
			return "audio/mp3"
			break
		case "mp4"
		case "m4a"
			return "audio/mp4"
			break
	end switch
end getAudioMime

function getAudioFile pA
	put getAudioFormat(pA) into tFormatA
	get (folderForAudio(pA) & "/" & tFormatA["filename"] )
	replace $_SERVER["DOCUMENT_ROOT"] with empty in it
	rigLogMessage "debug","getAudioFile:" && it
	return it
	--put ("audio/" & tFormatA["format_name"] ) into gData["format_mime"]
	put ("audio/" & "mp3" ) into gData["format_mime"]
end getAudioFile

# function getAudioFile pA, pFormat
# 	put getAudioFormat(pA, pFormat) into tFormatA
# 	get (folderForAudio(pA) & "/" & tFormatA["filename"] )
# 	replace $_SERVER["DOCUMENT_ROOT"] with empty in it
# 	rigLogMessage "debug","getAudioFile:" && it
# 	return it
# 	put ("audio/" & tFormatA["format_name"] ) into gData["format_mime"]
# end getAudioFile

/*
function getAudioMime pA, pFormat
	put getAudioFormat(pA, pFormat) into tFormatA
	get (folderForAudio(pA) & "/" & tFormatA["filename"] )
	return ("audio/" & tFormatA["format_name"] )
end getAudioMime
*/

function getFeaturedAudioImage pRecordA

# BR: 2012-08-29
# this handler gets the genre of the audio that is being picked by the random picker
# it looks up the folder in /html/looklisten/img/feature-audio-posters
# and passes the URL for the image to the view.

put pRecordA["media_type"] into tAudioType
put pRecordA["genre"] into tGenre
put pRecordA["author"] into tAuthor
put pRecordA["deity"] into tDeity

rigLogMessage "debug", "Getting Audio Info" & tAudioType & tGenre & tAuthor & tDeity

# start with more specific cases and move to general

	switch 
		case "inspiredtalk" is in tAudioType
		# only two kinds here Bodhinatha and Gurudeva
		   if "Bodhinatha" is in tAuthor then
		      put "bodhinatha" into tImageFolder
	      else
		      put "gurudeva" into tImageFolder
	      end if
	      break
	     case "natchintanai" is in tGenre
		      put "natchintanai" into tImageFolder
	       break
	      
	   case ( ("chant" is in tAudioType) or ("stotram" is in tGenre) )
		      put "sanskrit" into tImageFolder
	       break
	  # bhajans and Gitams will normally be assigned to a Deity
	  # check that first and exit.
	    case "Ganesha" is in tDeity
		      put "bhajan-gitam/ganesha" into tImageFolder
	       break
	        case "Muruga" is in tDeity
		      put "bhajan-gitam/muruga" into tImageFolder
	       break
	       case "Siva" is in tDeity
		      put "bhajan-gitam/siva" into tImageFolder
	       break
	  # if not any of those deities then we just for use other
	      case ( ( "bhakti-gitam" is in tGenre) or ("bhajan" is in tGenre) )
	         put "bhajan-gitam/other" into tImageFolder
	       break 
	       
	       # only one left now!
	       
	       case "Tirumurai" is in tGenre
		      put "Tamil" into tImageFolder
	       break
	       
	end switch
	
	# now we just have to set the default folder next, 
	# get a random path
	# and pass the string to the URL in the view.
	
	 
	 put "/html/looklisten/img/featured-item-posters/" into tWebFolderPath
	
     put $_SERVER["DOCUMENT_ROOT"] & tWebFolderPath into tAudioPostersPathStem
     
     put tAudioPostersPathStem &  tImageFolder into tTargetFolder
     
     put rigGetFileNames(tTargetFolder) into tPosters
     put rigArrayRandElement(tPosters) into tImage
     return (tWebFolderPath&tImageFolder & "/" & tImage)
     
        
end getFeaturedAudioImage

function getPathForMP3 pRecordA
	put getAudioFormat(pRecordA, "mp3") into tFormatA
	get (folderForAudio(pRecordA) & "/" & tFormatA["filename"] )
	replace $_SERVER["DOCUMENT_ROOT"] with empty in it
	return it
end getPathForMP3



