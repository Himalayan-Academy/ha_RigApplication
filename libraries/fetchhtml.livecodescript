script "fetchhtml"

global gRigA, gData ---------- rabit
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
        rigLogMessage "debug", "Fetch HTML Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack

/* Brahmanathaswami 2012/3/25

# this is acopy of site.lc with slight modifications for 
# testing purposes

*/



local sPageToLoad, sHTMLFolder, sPageMetadataA

# RUN INITIAL CONFIGURATION PROCEDURES
# Whether Need or Not
command rigRunInitialFetchhtmlConfig pConfig
	-- rigLogMessage "debug", "Fetch HTML Library Loaded" -------------- rabit
end rigRunInitialFetchhtmlConfig

command fetchExternalHTML
	rigLogMessage "debug", "Loading fetchhtml library"
	put $_SERVER["DOCUMENT_ROOT"] & "/html/" into sHTMLFolder	


put rigUriString() into sPageToLoad

	rigLogMessage "debug","page to load:" && sPageToLoad
	
	## Cascading metadata file.
	
	# first pick default.metadata from toplevel folder and downwards.
	set the itemdel to "/"
	repeat with x = 1 to (the number of items in sPageToLoad - 1)
			put item x of sPageToLoad & "/" after tFolder
		
			# then here you could use:
			# put sHTMLFolder & tFolder & tEnclosingFolder &".metadata" into sPageMetadataFile
			# instead of this:
		
			put sHTMLFolder & tFolder & "default.metadata" into sPageMetadataFile
			rigLogMessage "debug","looking for" && sPageMetadataFile
		
			if there is a file sPageMetadataFile then
				rigLogMessage "debug","found metadata file at:" && sPageMetadataFile	
				put url ("file:" & sPageMetadataFile) into tTempMetadataA
				put jsontoarray(tTempMetadataA) into tTempMetadataA
				repeat for each key tK in tTempMetadataA
					rigLogMessage "debug", (tFolder & "default.metadata -->" && tK && tTempMetadataA[tK] )
					put tTempMetadataA[tK] into sPageMetadataA[tK]
				end repeat
			end if
	end repeat
	

	# Now check for override
	put sHTMLFolder & sPageToLoad & ".metadata" into sPageMetadataFile
	if there is a file sPageMetadataFile then
		rigLogMessage "debug","found metadata file at:" && sPageMetadataFile	
		put url  ("file:" & sPageMetadataFile) into tTempMetadataA
		put jsontoarray(tTempMetadataA) into tTempMetadataA
		repeat for each key tK in tTempMetadataA
			rigLogMessage "debug", (sPageToLoad && "-->" && tK && tTempMetadataA[tK] )
			put tTempMetadataA[tK] into sPageMetadataA[tK]
		end repeat
	end if
	
	# Check if it is an index.html call
		
	if there is not a file ( sHTMLFolder & sPageToLoad & ".html") then
		if there is a file ( sHTMLFolder & sPageToLoad & "/default.metadata") then
			put sHTMLFolder & sPageToLoad & "/default.metadata" into sPageMetadataFile
			rigLogMessage "debug","found metadata file at:" && sPageMetadataFile	
			if there is a file sPageMetadataFile then
				put url  ("file:" & sPageMetadataFile) into tTempMetadataA
				put jsontoarray(tTempMetadataA) into tTempMetadataA
				repeat for each key tK in tTempMetadataA
					rigLogMessage "debug", (sPageToLoad && "-->" && tK && tTempMetadataA[tK] )
					put tTempMetadataA[tK] into sPageMetadataA[tK]
				end repeat
			end if
		end if
	end if
	

	
end fetchExternalHTML

command viewExternalPage
rigLogMessage "debug","fetching page: " && sPageToLoad
	put sPageMetadataA["title"] into gData["pageTitle"] 
	put url ("file:" & sHTMLFolder & sPageMetadataA["sidebar"]) into gData["sidebar"]
   
   # gData["sidebar"] needs to be merged before view two-column.lc is loaded because music-sidebar.html ----- rabit
   # which is merged in two-column.lc includes gData to be merged too, the merge ----- rabit
   # function as used by rigLoadView does not merge nested expressions -------- rabit
	put merge(gData["sidebar"]) into gData["sidebar"] --------------------------- rabit
	# BR: 2012/3/21: I changed the key names  to "page_heading" "top_navigation" and "secondary_navigation" and 
	
	put getSetHeadNav(sPageMetadataA["body_class"],sPageMetadataA["page_heading"],sPageMetadataA["top_navigation"],sPageMetadataA["secondary_navigation"]) into gData["pageHeader"]
	
	switch
		case there is a file (sHTMLFolder & sPageToLoad & ".html")
			rigLogMessage "debug", "loading external page:" &&  (sHTMLFolder & sPageToLoad & ".html")
			  put the merge of  url (("file:" &sHTMLFolder & sPageToLoad & ".html")) into gData["singleArticle"]
			   if gData["singleArticle"] is empty then
				  put "empty" into tFileData
			  else 
				  put line 1 of gData["singleArticle"] into tFileData
			  end if
			  rigLogMessage "debug", "external file was loaded as: " && tFileData
			updatePageMetadataIfPathOnDiskChanged ("/" & sPageToLoad & ".html")	
		break
		case there is a file (sHTMLFolder & sPageToLoad & "/index.html")
			rigLogMessage "debug", "loading external page:" && (sHTMLFolder & sPageToLoad & "/index.html")
			  put the merge of  url (("file:" &sHTMLFolder & sPageToLoad & "/index.html")) into gData["singleArticle"]
			updatePageMetadataIfPathOnDiskChanged ("/" & sPageToLoad & "/index.html")	
		break
	end switch
   -- get rigLoadView(("sitewide/" & sPageMetadataA["template"]), gData)
   get rigLoadView("sitewide/" & sPageMetadataA["template"]) ------ rabit
end viewExternalPage


