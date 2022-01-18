script "getquotes"

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
        rigLogMessage "debug", "Get Quotes Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues -------------------- rabit
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
command rigRunInitialGetQuotesConfig
	-- rigLogMessage "debug", "getQuotes Library Loaded" ------------- rabit
end rigRunInitialGetQuotesConfig


command getOneQuote
	# rigLogMessage "Library:getQuotes", "Handler:getOneQuote is firing"
	# rigLogMessage "Are Segs being passed thru to here?", ("ID:" && tSegs[3])	
				
	rigDbSelect "content"
	rigDbWhere "quote_id", tSegs[3]
	put rigDbGet("quote") into tQuoteQuery
	put tQuoteQuery["resultarray"][1] into tRow
	put tRow[1] into gData["gurudevaQuote"] 	
	put "/media/apps/gurudeva/img/" & tSegs[4] & ".jpg" into gData["gurudevaPhoto"]
	
end getOneQuote
 