script "fetchtalksindex"

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
        rigLogMessage "debug", "FetchInspiredTalks Index Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



/* Brahmanathaswami 2014/2/18

# used to fetch metadata on InspiredTalks from the database

*/


# RUN INITIAL CONFIGURATION PROCEDURES

	command rigRunInitialfetchtalksindexConfig pConfig
		-- rigLogMessage "debug", "FetchInspiredTalks Index Loaded" ---------- rabit
	end rigRunInitialfetchtalksindexConfig


local tTalksList,tAuthor,tOutput,tAuthorList

function buildAccordion tTalksList,tAuthor

    ##### mark up the data with HTML for accordion
    ### See Kyle Hamilton's samples in the manager section under sample code

	set the itemdel to "|"
	put 0 into tYear

	repeat for each line x in tTalksList 
		
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

command fetchInspiredTalkData 

	if gReporttype is empty then 
		put "all" into gReportType
	end if

	rigDbWhere "media_type", "audio/inspiredtalk"
	rigDbWhere "approved_for_public", "YES"

	rigTimeMark "dbGet_start"
	
	put rigDbGet("item") into tTalksQuery

	rigTimeMark "dbGet_end"

	put tTalksQuery["numrows"] into tTalksRowCount


######## Ralf's Version with column picker
## allows us to use a for each (very fast!) construct for the dig

put rigDbListFields("item") into tFields

repeat for each key tKey in tFields
   put tKey into tColumns[tFields[tKey]]
 end repeat

rigTimeMark "extractData_start"

	# CHECK IF THE QUERY RESULT HAS DATA
	if tTalksQuery["numrows"] > 0 then

	  # THIS IS USED TO DEFINE THE PARTICULAR ROW NUMBER
	  put 0 into tIncr
	  
	  # Extract a simple pipedelimited list

     repeat for each key tKey in tTalksQuery["resultarray"]
	     add 1 to tIncr
	     put tTalksQuery["resultarray"][tIncr] into tRow
	     put empty into tEntry
	     put tRow[tColumns["date_created"]] & "|" into tEntry
		 put tRow[tColumns["author"]] & "|" after tEntry
		 # put "Click to View" into tArray["title"]

		 put tRow[tColumns["file_id"]] into tFileID
		 put tRow[tColumns["title"]] into tTitle  
	   
	    #put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]], tArray)  INTO tTitleLink
	     put  rigAnchor( ("/view/"&tRow[tColumns["file_id"]]) ,tRow[tColumns["title"]])  INTO tTitleLink
	    
	   
	     put tTitleLink after tEntry

			    # later: put tRow[tColumns["description"]] after tEntry
	     put tEntry & cr after tTalksList
		    
	 end repeat
	end if

## some anchors are not being closed. Identify these and append to output
## check database later for bad chars in the fields
	repeat for each line y in tTalksList
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
   sort lines of tTalksList descending by item 1 of each 
   sort lines of tTalksList descending by item 2 of each

	
   
   # set up triggers in advance
   
     put "Satguru Sivaya Subramuniyaswami" into tAuthor
   put 0 into tYear
   
   # Start the accordion for Gurudeva
   # Heading first
   put "<h2>"  & "Satguru Sivaya Subramuniyaswami" & "</h2>" & cr into tOutput
   put format ("<ul class=\"accordion\">")  & cr after tOutput

   put buildAccordion(tTalksList,tAuthor,tYear) after tOutput
   
   # After the first set is done we are ready to move on
   # close the last accordion 
   
   put "</ul>" & cr &"</li>" & cr & "</ul>" & cr   after tOutput
   
   # New heading and accordion
   put "<h2>"  & "Satguru Bodhinatha Veylanswami" & "</h2>" & cr after tOutput
   put format ("<ul class=\"accordion\">")  & cr into tBDTalks
   
   # reset year triggers:
    put "Satguru Bodhinatha Veylanswami" into tAuthor
   put 0 into tYear
   
   # Bodhinatha's talks
   
   # first we need to delete all of Gurudeva's Talks
   put lineoffset("Bodhinatha",tTalksList) into tBeginNewSection
   delete line 1 to (tBeginNewSection-1)  of tTalksList
   

# we have other talks now by Sadasivanathswami and this all breaks if
# there is an author other than Bodhinatha in "tAuthor" var
# But this means any entry where Bodhinatha's name is miss entered will 
# also be filtered out of the list.

  filter tTalksList with "*Satguru Bodhinatha Veylanswami*"

   put buildAccordion(tTalksList,tAuthor,tYear) after tBDTalks
   
   # close last divs and we are done
   put "</ul>" & "</ul>"  & cr after tBDTalks
   
    put "<br />" after tBDTalks
    put tMissingTags after tBDTalks
    
		put tBDTalks into gData["BDAudioList"]
		put tBDTalks after tOutput
		put tOutput into gData["talksListing"]
	
end fetchInspiredTalkData

command fetchRandomGurudevaTalk
    rigDbWhere "media_type", "audio/inspiredtalk"
	rigDbWhere "approved_for_public", "YES"
	rigDBWhere "author", "Satguru Sivaya Subramuniyaswami"	
	put rigDbGet("item") into tTalksQuery	
	put tTalksQuery["numrows"] into tTalksRowCount
	put random(tTalksRowCount) into tRandomTalk
	 put tTalksQuery["resultarray"][tRandomTalk] into tRow
	put tRow[2] into tFileID
    put tRow[5] into tTitle
    put tRow[53] into tDateCreated
    set the itemdel to "-"
	put item 1 of tDateCreated into tYear 
	put "/inspired-talks/gurudeva/" & tYear &"/"& tFileID &"/"& (tFileID&".mp3") into tLocation
    put "https://www.himalayanacademy.com/media/audio"& tLocation into tURL
    put tURL &"|"& tTitle  into gData["oneRandomGurudevaTalk"]  
end fetchRandomGurudevaTalk