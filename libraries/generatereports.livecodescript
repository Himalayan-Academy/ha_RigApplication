script "generatereports"

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
        rigLogMessage "debug", "Generate Reports Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack

/* Brahmanathaswami 2013/6/24

# used by the manager controller to generate reports.

*/


# RUN INITIAL CONFIGURATION PROCEDURES
# Whether Need or Not
command rigRunInitialGenerateReportsConfig
	-- rigLogMessage "debug", "generateReports Library Loaded" ------------- rabit
end rigRunInitialGenerateReportsConfig

# this command comes from the manager.lc controller
# gReportType is passed through from segment 3 in the URL

---------------
/* command getLyricsReport gReportType

if gReporttype is empty then 
	put "all" into gReportType
end if

rigDbWhere "media_type", "audio/song"

# find all records where lyrics are not empty.... we have four different fields.
# assume if translitertion
# fields are in database : lyrics_original, lyrics_original_transliteration, lyrics_literal_translation

if gReportType = "no-lyrics" then
   rigDbWhere "lyrics_original_transliteration =", " " # transliteration is empty
      else
  rigDbWhere "lyrics_original_transliteration >", "' '" # transliteration is not empty
end if	



switch gReportType # based on seg 3 of the URL

		 case "all"
		  	put "All Records With Lyrics" into tReportTitle
		 	break
		 case "no-lyrics"
		  	put "All songs Without Lyrics" into tReportTitle
		 	break
		 case "song-book"
		  	rigDbLike "tags", "Song Book"
		  	put "Scheduled for Song Book" into tReportTitle
		 	break
		 case "todo"
		 	rigDbLike "production_notes", "TO DO:"
		 	put "Next Steps" into tReportTitle
		 	break
		 case "final"
		 		rigDBLike "production_notes", "Lyrics are Final"
		 		put "Final" into tReportTitle
		 	break
		 case "deployed"
		 		rigDbWhere "approved_for_public", "YES"
		 		put "All Lyrics Deployed with Songs" into tReportTitle
		 	break
		 case "no-audio"
		        # cheap check on audio file: 
		        # assume if artist is entered, there is an MP3 on disk
		 		rigDbWhere "artists =", " "
		 		put "Lyrics Only, Need Audio" into tReportTitle
		 	break
		
 	
 	end switch

	
	# rigDBWhere "media_type","audio/song"

	put rigDbGet("item") into tLyricsQuery
	put tLyricsQuery["numrows"] into tLyricsRowCount
	
# we should redo this using the "for each" construct
	
   repeat with x = 1 to tLyricsQuery["numrows"]
	        put rigDbRow(x) into tRow
			put "Click to View" into tArray["title"]
	        put  rigAnchor( ("/view/"&tRow["file_id"]) ,tRow["title"], tArray)  INTO tData[x][1]	
			put tRow["item_id"]  into tData[x][2]
			put tRow["production_notes"] & cr &"<br /><b>Tags:</b> " &tRow["tags"] into tData[x][3]
			put tRow["artists"]  into tData[x][4]
			
				
	# we need to get more info here later: determine if there is a recording or not etc
		 						        
		end repeat
		    	    
		
# set up the output with a links header and a table. 
# We can pass the report type in each of the links

      rigSetTableHeading "<b>Title</b>,<b>ID</b>,<b>Notes-Tags</b>,<b>Artists</b>"
		put format("<th align=\"left\">") into tTmpl["headingCellStart"]
		put "<table border=" & quote & "1" & quote && "class=" & quote &"table-standard" & quote && "cellpadding=" & quote & "0" & quote && "cellspacing=" & quote & "2" & quote & ">" into tTmpl["tableOpen"]
		
		rigSetTableTemplate tTmpl 
	
				put rigGenerateTable(tData) into tListing  

				put  rigAnchor("/manager/lyrics-report/all","All Lyrics") & " | " INTO tReportLinks
				put  rigAnchor("/manager/lyrics-report/song-book","SSC Song Book") & " | " after tReportLinks
				put  rigAnchor("/manager/lyrics-report/todo","To Do") & " | " after tReportLinks
				put  rigAnchor("/manager/lyrics-report/final","Final") & " | " after tReportLinks
				put  rigAnchor("/manager/lyrics-report/deployed","All Live - Deployed") & " | " after tReportLinks
				put  rigAnchor("/manager/lyrics-report/no-audio","No Recording") & " | " after tReportLinks
				
				
				
				put "<p>" & tReportLinks& "</p>" into gData["singleArticle"]

				if tListing ="false" then put "No Such Records Yet" into tListing
				
				put "<p><b>" && tReportTitle &  " as of &mdash;" & the date & ": "&  tLyricsRowCount & " Lyrics</b></p>" & tListing after gData["singleArticle"]
				
	

	put "Kauai's Hindu Monastery - On Line Song Lyrics Report" into gData["pageTitle"] 
	put getSetHeadNav("landing","Song Lyrics Production Status",">Read &amp; Learn<","") into gData["pageHeader"]		
	get rigLoadView("sitewide/two-column") 

end getLyricsReport
*/
--------------------
command getBooksReport gReportType

 if gReportType is empty then put "atritex" into gReportType

 	rigDbWhere "media_type", "text/book"

	switch gReportType

		 case "atritex"
		  	rigDbLike "production_notes", "ATRITEX:"
		  	put "Pending from Atritex" into tReportTitle
		 	break
		 	case "todo"
		 	rigDbLike "production_notes", "TO DO:"
		 	put "Next Steps" into tReportTitle
		 	break
		 	case "completed"
		 		rigDBLike "production_notes", "Completed"
		 		put "Completed Titles" into tReportTitle
		 	break
		 	case "deployed"
		 		rigDbWhere "approved_for_public", "YES"
		 		put "All Publications That Are Approved and Deployed" into tReportTitle
		 	break
		 	case "not-live"
		 		rigDbWhere "approved_for_public", "NO"
		 			put "Records Entered but Not Published on Web Yet" into tReportTitle
		 	break
		
 	
 	end switch
 	
 	
	put rigDbGet("item") into tBookQuery
	put tBookQuery["numrows"] into tBookRowCount
	
	
   repeat with x = 1 to tBookQuery["numrows"]
	        put rigDbRow(x) into tRow
			put tRow["title"]  into tData[x][1]
			put tRow["item_id"]  into tData[x][2]
			put tRow["approved_for_public"]  into tData[x][3]
			put tRow["production_notes"] into tData[x][5]		        
	end repeat
		    	    
		     # dig the formats for the individual book
			repeat with x = 1 to tBookRowCount		 
			      put empty into tFormats			     
			         put "SELECT format_name FROM item_format WHERE item_id = :1" into tSQL
			         put  tData[x][2] into tArray[1]  # this it the item ID from above for each row
		             get rigDbQuery(tSQL, tArray) 
		             put rigDBresult() into tResult

					repeat for each key tKey in tResult
					    put tResult[tKey] into tRow
					    put tRow[1] & ", " after tFormats
					end repeat
					delete char -2 to -1 of tFormats
 			           put tFormats into tData[x][4]
 			end repeat	

  

		        			
		rigSetTableHeading "<b>Title</b>,<b>ID</b>,<b>Live</b>,<b>Formats</b>,<b>Notes</b>"
		put format("<th align=\"left\">") into tTmpl["headingCellStart"]
		put "<table border=" & quote & "1" & quote && "class=" & quote &"table-standard" & quote && "cellpadding=" & quote & "0" & quote && "cellspacing=" & quote & "2" & quote & ">" into tTmpl["tableOpen"]
		
		rigSetTableTemplate tTmpl 
	
				put rigGenerateTable(tData) into tListing  

				put  rigAnchor("/manager/book-report/atritex","Atritex In Progress") & " | " INTO tReportLinks
				put  rigAnchor("/manager/book-report/todo","To Do") & " | " after tReportLinks
				put  rigAnchor("/manager/book-report/completed","Completed") & " | " after tReportLinks
				put  rigAnchor("/manager/book-report/deployed","All Live - Deployed") & " | " after tReportLinks
				put  rigAnchor("/manager/book-report/not-live","Not Deployed") & " | " after tReportLinks
				put  rigAnchor("/manager/channels","Channels") after tReportLinks
				
				put "<p>" & tReportLinks& "</p>" into gData["singleArticle"]
				
				put "<p><b>" && tReportTitle &  " as of &mdash;" & the date & ": "&  tBookRowCount & " Publications</b></p>" & tListing after gData["singleArticle"]
				
	

	put "Kauai's Hindu Monastery - On Line Publications Report" into gData["pageTitle"] 
	put getSetHeadNav("landing","Web Publications Production Status",">Read &amp; Learn<","") into gData["pageHeader"]		
	get rigLoadView("sitewide/two-column")  
	
end getBooksReport

command getQuotesReport  gReportType

put the seconds into tStartTimer

# 2015-08-20 wire to pick up only Tirumular quotes
    --#put "SELECT q.quote_id, q.content, q.subject, q.author,q.source_url, group_concat( c.name ) categories FROM quote q LEFT JOIN category_quote cq ON cq.quote_id = q.quote_id LEFT JOIN category c ON c.category_id = cq.category_id WHERE q.author = 'Saint Tirumular' GROUP BY q.quote_id, q.content;" into tQuoteSelection

# 2015-08-20  wire to pick up only Gurudeva quotes
    -- # put "SELECT q.quote_id, q.content, q.subject, q.author,q.source_url, q.entered_by, group_concat( c.name ) categories FROM quote q LEFT JOIN category_quote cq ON cq.quote_id = q.quote_id LEFT JOIN category c ON c.category_id = cq.category_id WHERE q.author = 'Satguru Sivaya Subramuniyaswami' GROUP BY q.quote_id, q.content;" into tQuoteSelection
    
#2015-05-31  wire to pick up a set based on quote ID range
 put "SELECT q.quote_id, q.content, q.subject, q.author,q.source_url, q.entered_by, group_concat( c.name ) categories FROM quote q LEFT JOIN category_quote cq ON cq.quote_id = q.quote_id LEFT JOIN category c ON c.category_id = cq.category_id WHERE q.quote_id < 1500 GROUP BY q.quote_id, q.content;" into tQuoteSelection

# 2015-10-30  wire to pick all quotes ; just remove the where clause
-- Active Query is Here! 

#     put "SELECT q.quote_id, q.content, q.subject, q.author,q.source_url, q.entered_by, group_concat( c.name ) categories FROM quote q LEFT JOIN category_quote cq ON cq.quote_id = q.quote_id LEFT JOIN category c ON c.category_id = cq.category_id GROUP BY q.quote_id, q.content;" into tQuoteSelection
	
	put rigDbQuery(tQuoteSelection) into tQuoteQuery
	
	put the seconds into tEndQuery
	put ((tEndQuery-tStartTimer)) & " seconds for query " into tEndQueryTime
	put tQuoteQuery["numrows"] into tQuoteRowCount
	put rigDBresult() into tQuotesList
	put 0 into tIncr
	repeat for each key tKey in tQuotesList
	   add 1 to tIncr
 
		put rigDbRow(tIncr) into tRow
		put tRow["content"]  into tData[x][1]
		put tRow["author"]  into tData[x][2]
		put tRow["author_dates"]  into tData[x][3]
		put tRow["source_url"] into tData[x][4]	
		put tRow["quote_id"] into tData[x][5]
		put tRow["categories"] into tData[x][6]	
		put tRow["entered_by"] into tData[x][7]	
		put tRow["subject"] into tData[x][8]	        
		# for web display
		# check for URL first and don't use any if it is empty
		if tData[x][4]	<> empty then
				put rigAnchor(tData[x][4],tData[x][4]) into tSourceURL
			else
				put "" into tSourceURL
		end if
        put tData[x][4] into tSourceURL
	
		put "<hr /><p>ID |" & tData[x][5]  &"| <br />"  & tData[x][1] & "<br /><br /><b>Author:</b> <i>" & tData[x][2] & "" & tData[x][3] \
		& "</i><br /><b>Source:</b> " & tSourceURL & "<br /><b>Categories: </b>"& tData[x][6] & "<br /><b>Entered by: " & tData[x][7] & " -- Subject: " & tData[x][8] & "</b></p>"  & cr after tListOfQuotes
		
		
		# Prep for lean view for app to call 
		# file is pipe and tab delimited... we don't know about unicode here yet. 
		# deal with returns in quotes
		
		replace cr with " " in tData[x][1]
		put tData[x][5]  & tab & tData[x][1] & tab & tData[x][2] & tab & tData[x][3] & tab & tData[x][4] & cr & "Categories: " & tData[x][6] & cr & "|" after tLeanListOfQuotes
	   
	end repeat
	
	    set the itemdel to "|"
		--sort lines of tListOfQuotes descending numeric by item 2 of each
		sort lines of tListOfQuotes ascending numeric by item 2 of each
		#delete line 501 to -1 of tListOfQuotes
	
	put the seconds into tEndBuildHTML
	put (tEndBuildHTML-tEndQuery) & " seconds to generate HTML" into tEndHTMLTime
	
	# export to drive for pick up by remote HTTP calls
	# change this later to the local server variable and move a small function over to HAP
	
	set the itemdel to tab
	sort lines of tLeanListOfQuotes ascending numeric by item 1 of each
	put tLeanListOfQuotes into url "file:/home/devhap/public_html/media/apps/sivasiva/quotes_1-1500.txt"
	 
	# web Preview next

	put "<p><b>All Quotes Report  " &&  " as of &mdash;" & the date & ": "&  tQuoteRowCount & " records; " & tEndQueryTime & "; " & tEndHTMLTime \
	& "</b></p>" into gData["singleArticle"]
	
	put tListOfQuotes after gData["singleArticle"]
	 
	
		put "HAP Quotes Database Report" into gData["pageTitle"] 
	put getSetHeadNav("landing","Quotes In Database",">Read &amp; Learn<","") into gData["pageHeader"]		
	get rigLoadView("sitewide/two-column")  

end getQuotesReport