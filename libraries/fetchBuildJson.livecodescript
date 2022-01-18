script "fetchBuildJson"

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
        rigLogMessage "debug", "Fetch Build Json Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ----------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



/* Brahmanathaswami 2021-08-05

# used to Build Json, fetch them to /media folder to so that can downloaded 
# initial project: 
# /media/books/books.json
# not finished right now and also not in use.... this is just a clone of the 
# lib used to fetch the inspired talks...
*/



# Add a few changes 

# RUN INITIAL CONFIGURATION PROCEDURES

	command rigRunInitialfetchSongsindexConfig
		-- rigLogMessage "debug", "FetchSongs Loaded" --------------- rabit
	end rigRunInitialfetchSongsindexConfig


local tSongsList,tAuthor,tOutput,tAuthorList

function buildAccordion tSongsList,tAuthor

    ##### mark up the data with HTML for accordion
    ### See Kyle Hamilton's samples in the manager section under sample code
    ### changes to test... where to we keep specifications?

	set the itemdel to "|"
	put 0 into tYear

	repeat for each line x in tSongsList 
		
			if (item 2 of x) <>  tAuthor then # we are done with one author's  listing
				exit repeat
			end if 

		# parse for the year

		put char 1 to 4 of (item 1 of x)  into tDate

			if (tDate<>tYear)  then # we are starting a new year

					if (tYear<>0) then # close previous submenu UL
						put  "</ul>"  & cr after tAuthorsList
					end if

				put tDate into tYear

				put  "<li>" & cr & "<h3>" & tYear &  ( format ("<span class=\"count\"></span>")) & "</h3> " &  cr & \
				format ("<ul class=\"sub-menu\">") & cr  after tAuthorsList

				# Add description UL here next...

			end if 

		# build list items next

		put "<li>" &(item 1 of x)& " - " &  (item 3 of x)  & "</li>" &cr after tAuthorsList

	end repeat

   return tAuthorsList

end buildAccordion

command fetchSongData pGenre,pDeity

	

	rigDbWhere "media_type", "audio/song"
	rigDbWhere "approved_for_public", "YES"

	if pGenre is not empty then
		rigDbWhere "genre", pGenre
	end if 
	if pDeity is not empty then
		rigDbWhere "diety", pDeity
	end if 
	

	

	rigTimeMark "dbGet_start"
	
	put rigDbGet("item") into tSongsQuery

	rigTimeMark "dbGet_end"

	put tSongsQuery["numrows"] into tSongsRowCount


######## Ralf's Version with column picker
## allows us to use a for each (very fast!) construct for the dig

put rigDbListFields("item") into tFields

repeat for each key tKey in tFields
   put tKey into tColumns[tFields[tKey]]
 end repeat

rigTimeMark "extractData_start"

	# CHECK IF THE QUERY RESULT HAS DATA
	if tSongsQuery["numrows"] > 0 then

	  # THIS IS USED TO DEFINE THE PARTICULAR ROW NUMBER
	  put 0 into tIncr
	  
	  # Extract a simple pipedelimited list
     repeat for each key tKey in tSongsQuery["resultarray"]
	     add 1 to tIncr
	     put tSongsQuery["resultarray"][tIncr] into tRow
	     put empty into tEntry
	     put tRow[tColumns["file_id"]] into tFileID
		 put tRow[tColumns["title"]] into tTitle  
	     put tRow[tColumns["artists"]] & "|" into tEntry
		 put tRow[tColumns["genre"]] & "|" after tEntry
		 put tRow[tColumns["deity"]] & "|" after tEntry
		 # put "Click to View" into tArray["title"]

		
	   
	    #put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]], tArray)  INTO tTitleLink
	     put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]])  INTO tTitleLink
	    
	   
	     put tTitleLink after tEntry

			    # later: put tRow[tColumns["description"]] after tEntry
	     put tEntry & cr after tSongsList
		    
	 end repeat
	end if

## some anchors are not being closed. Identify these and append to output
## check database later for bad chars in the fields
	repeat for each line y in tSongsList
		if not (y contains "</a>") then
			put y & "<br />" & cr after tMissingTags
		end if
	end repeat
	put "<!--" & cr before tMissingTags 
	put  "-->" after tMissingTags 

	##
	
	######## End Ralf's Version


	rigTimeMark "extractData_end"

   
   set the itemdel to "|"
   sort lines of tSongsList descending by item 1 of each 
   sort lines of tSongsList descending by item 2 of each

	# NEXT STEP: UPDATE THIS ROUTINE FOR THE DATA WE NEED FOR SONGS LISTING:
	# Songs are aggregated by Genre First, then Deity, then Title
	# but this accordion routine adopted from the talks index
	# does not offer that many levels deep
	# start simple with drop down for Genre
	# then drop down for title
   
   # set up triggers in advance
   # have to change this to loop through all Genres
   # if no genres is selected, or skip if only one genre is selected
   # For Bhajans we need to switch to Deity

   
     put "Satguru Sivaya Subramuniyaswami" into tAuthor
   put 0 into tYear
   
   # Start the accordion for Gurudeva
   # Heading first
   put "<h2>"  & "Satguru Sivaya Subramuniyaswami" & "</h2>" & cr into tOutput
   put format ("<ul class=\"accordion\">")  & cr after tOutput

   put buildAccordion(tSongsList,tAuthor,tYear) after tOutput
   
   # After the first set is done we are ready to move on
   # close the last accordion 
   
   put "</ul>" & cr &"</li>" & cr & "</ul>" & cr   after tOutput
   
   # New heading and accordion
   put "<h2>"  & "Satguru Bodhinatha Veylanswami" & "</h2>" & cr after tOutput
   put format ("<ul class=\"accordion\">")  & cr after tOutput
   
   # reset year triggers:
    put "Satguru Bodhinatha Veylanswami" into tAuthor
   put 0 into tYear
   
   # Bodhinatha's Songs
   
   # first we need to delete all of Gurudeva's Songs
   put lineoffset("Bodhinatha",tSongsList) into tBeginNewSection
   delete line 1 to (tBeginNewSection-1)  of tSongsList
   
   put buildAccordion(tSongsList,tAuthor,tYear) after tOutput
   
   
   # close last divs and we are done
   put "</ul>" & "</ul>"  & cr after tOutput
   
    put "<br /><br /><br />" after tOutput
    put tMissingTags after tOutput

    put tOutput into gData["SongsListing"]
	
-- end fetchSongsData
end fetchSongData --------------------------- rabit

