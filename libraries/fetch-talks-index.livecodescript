script "fetch-talks-index"

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
        rigLogMessage "debug", "Library_Name Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      _rigSetDefaultValues
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



/* Brahmanathaswami 2014/6/24

# used to fetch metadata on InspiredTalks from the database

*/


# RUN INITIAL CONFIGURATION PROCEDURES
# Whether Need or Not
	command rigRunInitialFetchInspiredTalksConfig
		rigLogMessage "debug", "FetchInspiredTalks Library Loaded"
	end rigRunInitialFetchInspiredTalksConfig


# Requirements: 
# we need to get the title, description
# year given to parse and sort by month and day
# author to segregate two sets: Bodhinatha - Gurudeva
# file_id to build the url


# command fetchInspiredTalkData Report
	command fetchInspiredTalkData 

	if gReporttype is empty then 
		put "all" into gReportType
	end if

	rigDbWhere "media_type", "audio/inspiredtalk"
	

	put rigDbGet("item") into tTalksQuery
	put tTalksQuery["numrows"] into tTalksRowCount

#### DEVELOPMENT CYCLE
  #	phase 1:

	# extract data into tab delimited format in the order of
	# date_created, author, title (linked with file_id), description

	 repeat with x = 1 to tTalksRowCount
		 	put empty into tEntry
	        put rigDbRow(x) into tRow
			put tRow["date_created"] & "--" into tEntry
			put tRow["author"]&& after tEntry
			put "Click to View" into tArray["title"]
	        put  rigAnchor( ("/view/"&tRow["file_id"]) ,tRow["title"], tArray)  INTO tTitleLink	
			put tTitleLink after tEntry
			# later: put tRow["description"] after tEntry   
			put "|" after tEntry
			put tEntry after tTalksList
	end repeat

	put tTalksList into gData["talksListing"]

	

	# sort the list by author and then year

	# create a link tagging function (revIgniter may have this)

	# Output and test the list to see of we are gettin proper order

	# the order needs to sort on the date ascending, Gurudeva 1957 - 2001

	# Bodhinatha 2001- 2014

  # phase 2:
    # set up variable for tAuthor.. insert "Sivaya Subramuniyaswami"
    # read first line, if author match then output Author header
    # if not a match, close previous div becaus we are moving to Bodhinatha
    # and set up the start of a new accordion, author title
    # set up data variable and insert bogus current year like 3001
    # extract the year from the first line
    # test the date against the current year
    # if not current year then close LI, close UL
    # set up the next header H3 tab
    # start the UL
    # start the next LI and html output (put this into a function)
    # repeat for next line



