script "fetchtalksdropdownindex"

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
        rigLogMessage "debug", "FetchInspiredTalks Drop Down Index Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues -------------------- rabit
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

	command rigRunInitialfetchtalksDropdownindexConfig
		-- rigLogMessage "debug", "FetchInspiredTalks Drop Down Index Loaded" -------- rabit
	end rigRunInitialfetchtalksDropdownindexConfig


local tTalksList,tAuthor,tOutput,tAuthorList,tOptionValueIncr

function buildDropdown tTalksList,tAuthor

# for each year we have to build  a line like this:
# <option value="yr0">2015</option>
#[[gData["talksYearsOptions"] ]]

    ##### mark up the data with HTML for accordion
    ### See Kyle Hamilton's samples in the manager section under sample code

	set the itemdel to "|"
	put 0 into tYear
	put 0 into tOptionValueIncr

	repeat for each line x in tTalksList 
		
			if (item 2 of x) <>  tAuthor then # we are done with one author's  listing
				exit repeat
			end if 

		# parse for the year
		# we have to create the first option choice
	
                Put item 1 of x into tCreatedDate
		put char 1 to 4 of tCreatedDate  into tDateYear
		
		
			# if the year does not change we don't do anything again
		# but append another option when the year changes

			if (tDateYear<>tYear)  then # we are starting a new year
			
			   if not (tYear=0) then
				  put (cr &"</div>" & cr) after gData["talksDropDivs"]
			  end if
			
			  
			put tDateYear into tYear
					
			
			         add 1 to tOptionValueIncr
		put format ("<option value=\"yr" & tOptionValueIncr & "\">" & tDateYear & "</option>" & cr) after gData["talksYearsOptions"]
                put format ("<div id=\"yr" & tOptionValueIncr& "\" class=\"drop\">" & cr ) after gData["talksDropDivs"] 
          else
				# Start the anchors
				put format (tCreatedDate & "&mdash;" & (item 3 of x) & " <br />" & cr)  after gData["talksDropDivs"] 
                    
			end if 


	end repeat

end buildDropdown

command fetchInspiredTalkData 

	rigDbWhere "media_type", "audio/inspiredtalk"
	rigDbWhere "approved_for_public", "YES"
	put rigDbGet("item") into tTalksQuery
	put tTalksQuery["numrows"] into tTalksRowCount


	put rigDbListFields("item") into tFields

	repeat for each key tKey in tFields
	   put tKey into tColumns[tFields[tKey]]
	 end repeat

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

   set the itemdel to "|"
   sort lines of tTalksList descending by item 1 of each 
   sort lines of tTalksList descending by item 2 of each
   
   # set up triggers in advance
   
     #put "Satguru Sivaya Subramuniyaswami" into tAuthor
#   put 0 into tYear
   
   # Now we have the date in a list that looks like this:
   # 2001-20-12|Satguru Sivaya Subramuniyaswami|<a href="/view/##file_id##">title</a>
   # build the dropdown for Gurudeva

   #put buildDropdown(tTalksList,tAuthor,tYear) after tOutput
   
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

   put buildDropdown(tTalksList,tAuthor,tYear) after tBDTalks
   
	
end fetchInspiredTalkData