script "epub"

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
        rigLogMessage "debug", "ePub Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "ePub Library Loaded" -------------- rabit

# DECLARE LOCAL VARIABLES
local _e

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialepubConfig pConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.
end rigRunInitialepubConfig

on epubClose pID
   revZipCloseArchive pID
   delete variable _e[pID]
end epubClose

function isThereAnEpubForFileID pID
	if there is a folder ($_SERVER["DOCUMENT_ROOT"] & "/media/books/" & pID & "/web") then
		return true
	else
		return false
	end if
end isThereAnEpubForFileID

on epubOpen pID, pFile
   rigLogMessage "debug", "trying to open ePub:" && pFile
   set the itemdel to slash
   get item 1 to -2 of pFile
   put the defaultfolder into tDF
   set the defaultfolder to it
   put the defaultfolder into tFolder
   put the defaultfolder into tRootFolder
   set the defaultfolder to tDF
   	
   
   #
   # Check out if the file is a valid ePub file
   #
   try
      switch
         case there is not a file pFile and there is not a folder (tFolder & "/web")
            rigLogMessage "error", "file not found:" && pFile
            throw "epuberr, file not found"
            break
      end switch
      
      # Unzip the file to known place ...
      
      if there is not a folder (tFolder & "/web") then
         rigLogMessage "debug", "creating web folder"
         set the defaultfolder to tFolder
         create folder "web"
         put tFolder & "/web" into tFolder
         revZipOpenArchive pFile, "read"
         if the result is not empty then
            rigLogMessage "error", "can't open zip file:" && the result
            throw "epuberr",the result
         else
			rigLogMessage "debug","Unziping EPub File"
            put revZipEnumerateItems(pFile) into tFileList
            repeat for each line tCompressedItem in tFileList
               add 1 to x
               put the number of lines in tFileList into tTotal
               rigLogMessage "debug","extracting" && x && "of" && tTotal && tCompressedItem
               if char -1 of tCompressedItem is "/" then next repeat
               set the itemdel to slash
               put (tFolder & "/" & tCompressedItem) into tOutput
               repeat with x = 1 to the number of items in tOutput - 1
                  put item x of tOutput & "/" after tPart
                  if there is not a folder tPart then
                     create folder tPart
                  end if
               end repeat
               put empty into tPart
               revZipExtractItemToFile pFile, tCompressedItem, tOutput
               if the result is not empty then
                  throw "epuberr",the result && tCompressedItem && tOutput
                  rigLogMessage "error", "epuberr," && the result && tOutput
                  exit repeat
               end if
            end repeat
			rigLogMessage "debug","End of Unziping EPub File"
			
         end if
         set the itemdel to slash
         get item 1 to -2 of pFile
         put the defaultfolder into tDF
         set the defaultfolder to it
         put the defaultfolder into tFolder
         put the defaultfolder into tRootFolder
         set the defaultfolder to tDF
      end if


	#
	# END OF UNZIP
	#
      
      #
      # File is potentialy unzipped now ...
      #
      
      
      # no error so far, means the file is unzipped.
      set the defaultfolder to (tFolder & "/web")
      rigLogMessage "debug", "folder:"&&the defaultfolder
      get url "file:mimetype"
      if "application/epub+zip" is not in it then
         throw "epuberr, wrong mimetype"  && it
      end if
      
      # file looks good. let us read META-INF/container.xml
      get revCreateXMLTreeFromFile("META-INF/container.xml", true, true, false)
      if it is not a number then
         throw "epuberr, META-INF/container.xml is not valid xml"
      end if
      
      put it into _e[pID]["ids"]["META-INF/container.xml"]
      
      # pick the rootfile
      get revXMLMatchingNode(_e[pID]["ids"]["META-INF/container.xml"], "/container/rootfiles", "rootfile", "media-type", "application/oebps-package+xml",1)
      # pick the content file
      get revXMLAttribute(_e[pID]["ids"]["META-INF/container.xml"], it, "full-path")
      rigLogMessage "debug",("rootfile path:" && it)
      put it into tRootFilePath
      # read the file ...
      get revCreateXMLTreeFromFile(it, true, true, false)
      if it is not a number then
         throw "epuberr, rootfile is not a valid XML file."
      end if
      put it into _e[pID]["ids"]["rootfile"]
      # set the defaultfolder to where the content is (usually OEBPS)
      set the defaultfolder to item 1 to -2 of tRootFilePath
      put item -2 of tRootFilePath into _e[pID]["rootfolder"]
      rigLogMessage "debug","default folder:" && the defaultfolder
      rigLogMessage "debug","root folder:" &&  _e[pID]["rootfolder"]
      			
      # process spine
      put revXMLNumberOfChildren(_e[pID]["ids"]["rootfile"], "/package/spine","itemref",1) into tItemCount
      repeat with x = 1 to tItemCount
         put format("/package/spine/itemref[%d]", x) into tNode 
          
         # pick the idref
         get revXMLAttribute(_e[pID]["ids"]["rootfile"], tNode, "idref")
                    # find the item inside the manifest with the same id
       get revXMLMatchingNode(_e[pID]["ids"]["rootfile"], "/package/manifest", "item", "id", it,1)
         # get the href for the item
         put revXMLAttribute(_e[pID]["ids"]["rootfile"], it, "href") into _e[pID]["spine"][x]
         
         --rigLogMessage "debug","spine" && x &&  _e[pfile]["spine"][x]
      end repeat
      
      
      # Parse table of contents
      rigLogMessage "debug", "looking for table of contents"
      get revXMLMatchingNode(_e[pID]["ids"]["rootfile"], "/package/manifest", "item", "media-type", "application/x-dtbncx+xml",1)
      get revXMLAttribute(_e[pID]["ids"]["rootfile"], it, "href")
      rigLogMessage "debug", "found TOC at" && it
      get revCreateXMLTreeFromFile(it, true, true, false)
      if it is not a number then
         rigLogMessage "error", "ncx error" && it
         throw "epuberr, table of contents file is not a valid XML file."
      end if
      put it into _e[pID]["ids"]["ncx"]
      # set the defaultfolder to where the content is (usually OEBPS)
      set the defaultfolder to item 1 to -2 of it
      # process TOC
      epubProcessTOCITems pID, "/ncx/navMap"
      set the defaultfolder to tDF
      put pFile into _e[pID]["filename"]
      
   catch tErrorCondition
      rigLogMessage "error", "epuberr:" && tErrorCondition
      return tErrorCondition
   end try
end epubOpen

command epubProcessTOCITems pID, pNode
	put revXMLNumberOfChildren(_e[pID]["ids"]["ncx"], pNode,"navPoint",1) into tItemCount
	try
	if tItemCount is not a number then
		#rigLogMessage "debug","eerror:" && tItemCount && pNode && the target
		exit epubProcessTOCITems
	end if
	rigLogMessage "debug","total items in TOC:" && tItemCount &&"from node:"& pNode && revXMLNodeContents(_e[pID]["ids"]["ncx"], (pNode & "/navPoint/navLabel/text"))
	 repeat with x = 1 to tItemCount
	    put format("%s/navPoint[%d]",pNode, x) into tNode
		put revXMLAttribute(_e[pID]["ids"]["ncx"], tNode, "playOrder") into tPlayOrder
			 
	    # pick the src
	    put revXMLAttribute(_e[pID]["ids"]["ncx"], (tNode & "/content"), "src") into tSrc
	    put revXMLAttribute(_e[pID]["ids"]["ncx"], tNode, "id") into tNodeID
		if tNodeID contains "#" then
			put the itemdel into tI
			set the itemdel to "#"
			put item 1 of tNodeID into tNodeID
			set the itemdel to tI
		end if
	      
	         	 
	         	  # pick the title for the item
			 put revXMLNodeContents(_e[pID]["ids"]["ncx"], (tNode & "/navLabel/text")) into tItemTitle
			 if "xmlerr" is not in tSrc and "xmlerr" is not in tItemTitle then
		 		 put tSrc into _e[pID]["toc"][tPlayOrder]["src"]
		 		 put tItemTitle into _e[pID]["toc"][tPlayOrder]["title"]
			 end if
			
			rigLogMessage "debug", x && "toc item:"&&tNodeID && tPlayOrder && tItemTitle && tNode
			 if revXMLNumberOfChildren(_e[pID]["ids"]["ncx"], tNode,"navPoint",1) > 0 then
				 #rigLogMessage "debug","I am recursing to" && tNode
				 epubProcessTOCItems pID, tNode
			end if
	  end repeat
	catch m
		throw m
	end try
end epubProcessTOCItems

function epubSpineItemNumberForTOCItem pID, pNum
	repeat for each key tK in _e[pID]["spine"]
		if _e[pID]["spine"][tK] is _e[pID]["toc"][pNum]["src"] then
			return tK
		end if
	end repeat
end epubSpineItemNumberForTOCItem

command ePubRegisterBaseURL pURL
	if char -1 of pURL is not "/" then put "/" after pURL
	put  ("http://"&$_SERVER["SERVER_NAME"]& pURL) into _e["base_url"]
end ePubRegisterBaseURL

function ePubBaseURL
	return _e["base_url"]
end ePubBaseURL

function epubURL pID, pURL
	put epubFilePathForID(pId) into tFilePath 
	return (_e["base_url"] & pID & "/web/"&_e[tFilePath]["rootfolder"]&"/" & pURL )
end epubURL

function epubURLWithFile pID, pFile
	put epubFilePathForID(pId) into tFilePath 
	return ("http://"&$_SERVER["SERVER_NAME"]&"/books/" & pID & "/" & pFile)
end epubURLWithFile

function epubTOC pID
	return  _e[pID]["toc"]
end epubTOC


function epubObject
	return _e
end epubObject

command ePubRegisterCodeForInjection pTag, pCode
	put pCode into _e["hooks"][pTag]
end ePubRegisterCodeForInjection

command ePubReplaceCode @pText, pTag, pLocation, pCode
	if pLocation is "above" then
		replace pTag with the merge of pCode && pTag in pText
	else
		replace pTag with pTag && the merge of pCode in pText
	end if
end ePubReplaceCode

command ePubPerformCodeInjections @pText
	repeat for each key tTag in _e["hooks"]
		put _e["hooks"][tTag] into tCode
		if "/" is in char 2 of tTag then
			put "below" into tLocation
		else
			put "above" into tLocation
		end if
		ePubReplaceCode pText, tLocation, tCode
	end repeat
end ePubPerformCodeInjections



function epubPathForSpineItem pID, pNum
	get ($_SERVER["DOCUMENT_ROOT"] &"/books/" & pID & "/web/"&_e[pID]["rootfolder"]&"/" & _e[pID]["spine"][pNum] )
	rigLogMessage "debug", "path for spine:" && it
	return it
end epubPathForSpineItem

function epubPathForTOCItem pID, pNum
	get ($_SERVER["DOCUMENT_ROOT"] &"/books/" & pID & "/web/"&_e[pID]["rootfolder"]&"/" & _e[pID]["toc"][pNum]["src"] )
	rigLogMessage "debug", "path for spine:" && it
	return it
end epubPathForTOCItem

function ePubSpineItem pID, pNum
	return _e[pID]["rootfolder"]&"/" &_e[pID]["spine"][pNum]
end ePubSpineItem

function epubFilePathForID pID
	return ($_SERVER["DOCUMENT_ROOT"] & "/books/" & pID & "/" & _e[pID]["filename"] & ".epub")
end epubFilePathForID

function epubPath pID
	return ($_SERVER["DOCUMENT_ROOT"] & "/books/" & pID & "/")
end epubPath

function epubSpine pID
	return _e[pID]["spine"]
end epubSpine

function ePubTocAsLinkedList pFileID, pShowSpineNumbers
	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]
		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath	
	epubOpen pFileID, tFilePath
	
	put the keys of _e[pFileID]["toc"] into tList
	sort numeric ascending tList
	repeat for each line x in tList
		put _e[pFileID]["toc"][x]["title"] into tLinkedListA[x]["title"]
		if pShowSpineNumbers is true then
			put epubSpineItemNumberForTOCItemNumber(pFileID, x) into k
		else
			put x into k
		end if
		put format("/book/%s/%s",pFileID,k) into tLinkedListA[x]["src"]
	end repeat
	
	return tLinkedListA
end ePubTocAsLinkedList


function ePubSpineAsLinkedList pFileID
	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]
		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath	
	epubOpen pFileID, tFilePath
	
	put the keys of _e[pFileID]["spine"] into tList
	sort numeric ascending tList
	repeat for each line x in tList
	# Test links
	put x into y 
	put y into tLinkedListA[x]["title"]
		
		#put _e[pFileID]["spine"][x]["title"] into tLinkedListA[x]["title"]
		put format("/book/%s/%s",pFileID,x) into tLinkedListA[x]["src"]
	end repeat
	
	return tLinkedListA
end ePubSpineAsLinkedList

function ePubTocItemAsIFRAME pFileID, pItem
	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]
		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath	
	epubOpen pFileID, tFilePath
	
	put ("binfile:" & $_SERVER["DOCUMENT_ROOT"] & format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["toc"][pItem]["src"]) ) into tPath
	put url tPath into tContent
	if "svg:" is not in tContent then
		put format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["toc"][pItem]["src"]) into gData["book"]["src"]
	else
		put format("/slurp/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["toc"][pItem]["src"]) into gData["book"]["src"]
	end if
	
	put mergeView("/cloudreader/simplereader-iframe") into tRetVal
	return tRetVal
end ePubTocItemAsIFRAME

function ePubSpineItemAsIFRAME pFileID, pItem
	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]
		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath	
	epubOpen pFileID, tFilePath
	
	put ("binfile:" & $_SERVER["DOCUMENT_ROOT"] &  format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["spine"][pItem])  ) into tPath
	put url tPath into tContent
	if "svg:" is not in tContent then
		put  format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["spine"][pItem])  into gData["book"]["src"]
	else
		put  format("/cloudreader/nosvg/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["spine"][pItem])  into gData["book"]["src"]
	end if
	
	
	
	put mergeView("/cloudreader/simplereader-iframe") into tRetVal
	return tRetVal
end ePubSpineItemAsIFRAME

function epubSpineItemNumberForTOCItemNumber pID, pTocItemNumber
	put _e[pID]["toc"][pTocItemNumber]["src"] into tSrc
	rigLogMessage "debug", "spine looking for item:" && tSrc
	put the keys of _e[pID]["spine"] into tKeys
	sort tKeys numeric
	repeat for each line k in tKeys
		set the itemdel to "#"
		put item 1 of tSrc into tAbsoluteSrc
		if tAbsoluteSrc is in _e[pID]["spine"][k] then
			return k
		end if
	end repeat
	return empty
end epubSpineItemNumberForTOCItemNumber


function epubNextSpineItemForTOCItem pID, pTocItemNumber
	put _e[pID]["toc"][pTocItemNumber]["src"] into tSrc
	put the keys of _e[pID]["spine"] into tKeys
	sort tKeys numeric
	repeat for each line k in tKeys
		rigLogMessage "debug", "compare" && tSrc &"|"& _e[pID]["spine"][k]
		if tSrc is in _e[pID]["spine"][k] then
			rigLogMessage "debug", "achei" && _e[pID]["spine"][k+1]
			return _e[pID]["spine"][k+1]
		end if
	end repeat
	return empty
end epubNextSpineItemForTOCItem

function epubPreviousSpineItemForTOCItem pID, pTocItemNumber
	put _e[pID]["toc"][pTocItemNumber]["src"] into tSrc
	put the keys of _e[pID]["spine"] into tKeys
	sort tKeys numeric
	repeat for each line k in tKeys
		if k is 1 then
			next repeat
		end if
		if tSrc is in _e[pID]["spine"][k] then
			return _e[pID]["spine"][k-1]
		end if
	end repeat
	return empty
end epubPreviousSpineItemForTOCItem

# Atritex is inserting name anchors at the of the TOC navPoint ID's
# e.g. "dws_some-mandala.html#Sec1"...  as these
# match the url src path because the TOC is supposed to drop down into the page
# but the package.opf ID's are not a match, they just have
#  "dws_some-mandala.html" so we need to truncate that ID somewhere 
# in the procedures to get things to work.

function stripNameAnchor tNavPointID
       if tNavPointID contains "#" then
		       put  (offset ("#",tNavPointID))-1 into tTrunc
		       put   char 1 to  tTrunc  of tNavPointID into tNavPointID
	          return tNavPointID
      else
           return tNavPointID
    end if
end stripNameAnchor

# 
# MONOCLE SUPPORT
#

function bookpath pID, pFile
	return ($_SERVER["DOCUMENT_ROOT"] & "/media/books/" & pID & "/" & pFile)
end bookpath

function monocleGetBookDataObject pFileID
	
	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]
		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath	
	epubOpen pFileID, tFilePath
	
	-- Set base url
	set the itemdel to "/"
	put item 1 to -2 of format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["spine"][1]) into gData["base url"]
		
	-- Begin book object
	put "var bookData = {" & cr into tObj
	
	-- GET COMPONENTS
	-- generated based on spine
	put "getComponents: function () {" & cr after tObj
	put "return [" & cr after tObj
	put the keys of _e[pFileID]["spine"] into tList
	sort numeric ascending tList
	repeat for each line x in tList
		if "cover" is in _e[pFileID]["spine"][x] or "_cc" is in _e[pFileID]["spine"][x] then
			next repeat
		end if
		put format("'/media/books/%s/web/%s/%s',\n",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["spine"][x]) after tObj
	end repeat
	delete char -2 of tObj
	put "];" & cr after tObj
	put "}," & cr after tObj
	-- END OF GET COMPONENTS
	
	-- GET CONTENTS
	-- generated based on toc
	put "getContents: function () {" & cr after tObj
	put "return [" & cr after tObj
	put the keys of _e[pFileID]["toc"] into tList
	sort numeric ascending tList
	repeat for each line x in tList
		put "{"  & cr after tObj
		replace quote with "'" in   _e[pFileID]["toc"][x]["title"]
		put "title:" & quote & _e[pFileID]["toc"][x]["title"] & quote & comma  & cr after tObj
		replace "#toc-anchor" with empty in _e[pFileID]["toc"][x]["src"]
		put "src:" & quote & format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["toc"][x]["src"])& quote  & cr after tObj
		put "}," & cr after tObj
	end repeat
	delete char -2 of tObj
	put "];" & cr after tObj
	put "}," & cr after tObj
	
	get format("/media/books/%s/web/%s/%s",pFileID,_e[pFileID]["rootfolder"],_e[pFileID]["toc"][1]["src"])
	set the itemdel to "/"
	put item 1 to -2 of it & "/" into gData["base url"]
	replace "//" with "/" in gData["base url"]
	-- END OF GET CONTENTS
	
	-- GET COMPONENT
	put "getComponent: function(componentId) {" & cr after tObj
	put "return this.getViaAjax(componentId);" & cr after tObj
    #put "return {" & cr after tObj
	#put the keys of _e[pFileID]["spine"] into tList
	#sort numeric ascending tList
	#repeat for each line x in tList
	#	put url ("file:" & $_SERVER["DOCUMENT_ROOT"]& format("/media/books/%s/web/OEBPS/%s",pFileID,_e[pFileID]["spine"][x])) into tHTMLData
	#	put lineoffset("<body>", tHTMLData) into tStart
	#	put lineoffset("</body>", tHTMLData) into tEnd
	#	put line 10 to -3 of tHTMLData into tHTMLData
	#	replace quote with "\" & quote in tHTMLData
	#	replace cr with empty in tHTMLData
	#	replace lf with empty in tHTMLData
	#	replace crlf with empty in tHTMLData
	#	replace numToChar(10) with empty in tHTMLData
	#	replace numToChar(13) with empty in tHTMLData
	#	
	#	
	#    put "'" & _e[pFileID]["spine"][x] & format("':\"%s\",", tHTMLData) & cr after tObj
	#end repeat
	#delete char -2 of tObj
    #put "}[componentId];" & cr after tObj
  	put "}," & cr after tObj
	-- END OF GET METADATA
	
	-- GET METADATA
	put "getMetaData: function(key) {" & cr after tObj
    put "return {" & cr after tObj
    put "title: " &quote & tBookA["title"]& quote &"," & cr after tObj
    put "creator: "&quote & tBookA["author"]& quote  & cr after tObj
    put "}[key];" & cr after tObj
  	put "}," & cr after tObj
	-- END OF GET METADATA
	
	-- AUXILIARY FUNCTIONS
	put "getViaAjax: function (path) {" & cr after tObj
    put "var ajReq = new XMLHttpRequest();" & cr after tObj
	put "path = '/cloudreader/slurp' + path;" & cr after tObj
    put "ajReq.open('GET', path, false);" & cr after tObj
    put "ajReq.send(null);" & cr after tObj
    put "return ajReq.responseText;" & cr after tObj
    put "}" & cr after tObj
	-- END OF AUXILIARY FUNCTIONS
	
	put "}" & cr after tObj
	put cr & "// generated:" && the milliseconds & cr after tObj
	put cr & cr after tObj
	
	return tObj
end monocleGetBookDataObject

# BR -- Added Following function to translate htmlPage request back to a spine number
# for incoming request for pages that have no wrapper, just an absolute path to
# the file inside /ops/xhtml/*.html

function epubFileRequestAsSpineNo pFileID, pHtmlFileName

	put getRecord(pFileID) into tBookA
	repeat for each key x in tBookA["formats"]
		if tBookA["formats"][x]["name"] is "epub" then
			put tBookA["formats"][x] into tEpubA
			exit repeat
		end if
	end repeat
	
	if  tEpubA["filename"] is empty then
		put pFileID & ".epub" into  tEpubA["filename"]
	end if
	
	put pFileID into gData["book"]["file_id"]		
	put bookPath(pFileID, tEpubA["filename"]) into tFilePath		
	epubOpen pFileID, tFilePath
	
	repeat for each key tSpineLine in _e[pFileID]["spine"]	
	  if _e[pFileID]["spine"][tSpineLine] contains pHtmlFileName then
	      put  tSpineLine into tSpineNumber
	   exit repeat
	  end if
    end repeat
	
	# put  "<br /><br />" & pHtmlFileName & "<br /><br />SpineNoContent: " & _e[pFileID]["spine"]["22"] after tList
	# put  "<br />Filename: " & tFilePath & "<br />End of Spine List" after tList	
	return tSpineNumber
		
end epubFileRequestAsSpineNo
					