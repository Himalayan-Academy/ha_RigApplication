script "pagemetadata"

global gRigA
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
        rigLogMessage "debug", "Page Metadata Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues -------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack



# LOGGING
-- rigLogMessage "debug", "Page Metadata Library Loaded" ------------ rabit

# DECLARE LOCAL VARIABLES

command rigRunInitialPageMetadataConfig pConfig

end rigRunInitialPageMetadataConfig 

function metadataForPage pPageURL
	if char -1 of pPageURL is "/" then
		delete char -1 of pPageURL
	end if
	
	
	if pPageURL is empty then
		put "/" into pPageURL 
	end if

	rigLogMessage "debug","looking metadata for" && pPageURL
	rigDbWhere "page_url", pPageURL
	put rigDbGet("page_metadata") into tQ
	put rigDbRow(1) into tRecordA
	return tRecordA
end metadataForPage

function setMetadataForPage pPageURL, pDataA
	
	if char -1 of pPageURL is "/" then
		delete char -1 of pPageURL
	end if	
	
	if char -1 of pDataA["page_url"] is "/" then
		delete char -1 of pDataA["page_url"] 
	end if
	
	if pDataA["page_url"] is empty then
		put "/" into pDataA["page_url"]
		put "/" into pPageURL 
	end if
	
	-- AAG: We now add the content of the page to the database.
	put ("binfile:" & $_SERVER["DOCUMENT_ROOT"] & "/html" & pDataA["path_on_disk"]) into tPath
	rigLogMessage "debug", "reading file:" && tPath
	put url tPath into pDataA["content"]
	
	put the seconds into tDate
	convert tDate to dateitems
	put sqldate(tDate) into pDataA["last_modified"]
	
	-- insert
	rigDbWhere "page_url", pPageURL
	put rigDbGet("page_metadata") into tQ
	if tQ["numrows"] is 0 then
		get rigDbInsert("page_metadata", pDataA)
	else
		rigDbWhere "page_url", pPageURL
		get rigDbUpdate("page_metadata", pDataA)
	end if
	rigDbWhere "page_url", pPageURL
	put rigDbGet("page_metadata") into tQ
	put rigDbRow(1) into tRecordA
	return tRecordA
end setMetadataForPage

command updatePageMetadataIfPathOnDiskChanged pFile
	-- Set page metadata
	put metadataForPage($_SERVER["REQUEST_URI"]) into tMetadataA
	if pFile is not  tMetadataA["path_on_disk"] or tMetadataA["content"] is empty then
		put pFile into tMetadataA["path_on_disk"]
		put $_SERVER["REQUEST_URI"] into tMetadataA["page_url"]
		get setMetadataForPage($_SERVER["REQUEST_URI"],tMetadataA)
	end if
end updatePageMetadataIfPathOnDiskChanged

function getAllPageMetadata
	put rigDbGet("page_metadata") into tQ
	repeat with x = 1 to tQ["numrows"]
		put rigDbRow(x) into tRecordsA[x]
	end repeat
	return tRecordsA
end getAllPageMetadata
	
	