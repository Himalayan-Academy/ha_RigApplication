script "fetchbooksindex"

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
        rigLogMessage "debug", "FetchBooks Index Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



/* Brahmanathaswami and Rajanatha 2015/11/30

# used to fetch metadata on books from the database

*/


# RUN INITIAL CONFIGURATION PROCEDURES

	command rigRunInitialfetchbooksindexConfig
		-- rigLogMessage "debug", "FetchBooks Index Loaded" -------------- rabit
	end rigRunInitialfetchbooksindexConfig

local tBooksList,tBookAuthor,tBookOutput,tBookAuthorList

command fetchbooksData 
	rigDbWhere "media_type", "text/book"
	rigDbWhere "approved_for_public", "YES"
	
	put rigDbGet("item") into tBooksQuery

	put tBooksQuery["numrows"] into tBooksRowCount


######## Ralf's Version with column picker
## allows us to use a for each (very fast!) construct for the dig

put rigDbListFields("item") into tFields

repeat for each key tKey in tFields
   put tKey into tColumns[tFields[tKey]]
 end repeat

	# CHECK IF THE QUERY RESULT HAS DATA
	if tBooksQuery["numrows"] > 0 then

		# THIS IS USED TO DEFINE THE PARTICULAR ROW NUMBER
		put 0 into tIncr

		# Extract a simple pipedelimited list

		repeat for each key tKey in tBooksQuery["resultarray"]
			add 1 to tIncr
			put tBooksQuery["resultarray"][tIncr] into tRow
			put empty into tEntry
			put tRow[tColumns["author"]] into tAuthor
			if tAuthor = "Satguru Bodhinatha Veylanswami" then 
				put tRow[tColumns["file_id"]] into tFileID
				put tRow[tColumns["title"]] into tTitle  
				put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]])  INTO tTitleLink
				put tTitleLink after tEntry
				put tEntry & "<br />" & cr after tBooksList
			end if 
		end repeat
	end if

	sort lines of tBooksList ascending by item 2 of each
	put tBooksList into gData["BDBookList"] 
	# set up triggers in advance
	# fetching only Bodhinatha's Talks for now...
	
end fetchbooksData 