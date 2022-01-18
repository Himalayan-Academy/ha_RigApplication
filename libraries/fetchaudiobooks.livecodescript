script "fetchaudiobooks"

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
        rigLogMessage "debug", "Fetch Audio Index Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



/* Brahmanathaswami 2018/12/16

# used to fetch index and metadata on audio books from the database

*/


# RUN INITIAL CONFIGURATION PROCEDURES

	command rigRunInitialfetchaudiobooksConfig pConfig
		-- rigLogMessage "debug", "Fetch Audio Index Loaded" ------------ rabit
	end rigRunInitialfetchaudiobooksConfig

local tAudioBookslist,tAudioBooksQuery

command fetchAudioBooksIndex 
	rigDbWhere "media_type", "audio/book"
	rigDbWhere "approved_for_public", "YES"
	
	put rigDbGet("item") into tAudioBooksQuery

	put tAudioBooksQuery["numrows"] into tAudioBooksRowCount

######## Ralf's Version with column picker
## allows us to use a for each (very fast!) construct for the dig

put rigDbListFields("item") into tFields

repeat for each key tKey in tFields
   put tKey into tColumns[tFields[tKey]]
 end repeat
 
	# CHECK IF THE QUERY RESULT HAS DATA
	if tAudioBooksQuery["numrows"] > 0 then

		# THIS IS USED TO DEFINE THE PARTICULAR ROW NUMBER
		put 0 into tIncr

		# Extract a simple pipedelimited list

		repeat for each key tKey in tAudioBooksQuery["resultarray"]
			add 1 to tIncr
			put tAudioBooksQuery["resultarray"][tIncr] into tRow
			put empty into tEntry
			put tRow[tColumns["file_id"]] into tFileID
			put tRow[tColumns["title"]] into tTitle  
			put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]])  INTO tTitleLink
			put tTitleLink after tEntry
			put tEntry & "<br />" & cr after tAudioBookslist
			
		end repeat
	end if

	sort lines of tAudioBookslist ascending by item 2 of each
	put tAudioBookslist into gData["audioBooksIndex"]
	
end fetchAudioBooksIndex