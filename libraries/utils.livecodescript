script "utils"

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
        rigLogMessage "debug", "Utils Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ----------------------- currently not needed ------ rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


-- # LOGGING
-- rigLogMessage "debug", "Utils Library Loaded" -------------------- rabit

# DECLARE LOCAL VARIABLES
global gData

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialutilsConfig
	rigLogMessage "debug", "Utils constructor called"
	rigLoaderLoadLibrary "fastjson"
end rigRunInitialutilsConfig

command outputJson pArrayA
	ct "application/json"
	put arrayToJson(pArrayA)
	quit
end outputJson

function q pText, pEscapeFormat
	switch pEscapeFormat
		case "JSON"
			replace quote with ("\" & quote) in pText
		break
	end switch
	return quote & pText & quote
end q

function getSafeRequestURI
	put rigVarServer("REQUEST_URI") into tURL
	if "?" is in tURL then
		set the itemdel to "?"
		put item 1 of tURL into tURL
	end if
	return tURL
end getSafeRequestURI

function getURLWithSearchTerms
	put getSafeRequestURI() into tURL
	repeat for each key k in gData["search terms array"]
		if k is not in tURL then
			rigLogMessage "debug", "url with search terms. k =" && k && urlencode(gData["search terms array"][k])
			put "/" & urlencode(k) & "/" & urlencode(gData["search terms array"][k]) after tURL
		else
			set the itemdel to "/"
			get itemoffset(k, tURL)
			put urlencode(gData["search terms array"][k]) into item (it + 1) of tURL
			rigLogMessage "debug", "url with search terms." && tURL
		
		end if
	end repeat
	return tURL
end getURLWithSearchTerms

function extracIDFromYoutubeURL pURL
	set the itemdel to "?"
	put item 2 of pURL into tParams
	split tParams by "&" and "="
	return tParams["v"]
end extracIDFromYoutubeURL

command downloadFileFromPath pPath
	set the itemdel to "/"
	put item -1 of pPath into tFileName
	put url ("binfile:" & $_SERVER["document_root"] & "/" & pPath) into tFileContent
	
	put header "Cache-Control: public"
	put header "Content-Description: File Transfer"
	put header "Content-Disposition: attachment; filename=" & tFileName
	put header "Content-Type: application/octet-stream"
	put header "Content-Transfer-Encoding: binary"
	put header "Content-Length:" && the len of tFileContent
	
	put binary tFileContent
end downloadFileFromPath


function zPad pT, pN
	repeat while the len of pT is not pN
		put 0 before pT
	end repeat
	return pT
end zpad


function sqldate pDate
	put zPad(item 1 of pDate, 4) into pYear
	put zPad(item 2 of pDate, 2) into pMonth
	put zPad(item 3 of pDate, 2) into pDay
	put zPad(item 4 of pDate, 2) into pHour
	put zPad(item 5 of pDate, 2) into pMinute
	put zPad(item 6 of pDate, 2) into pSecond
	
	put (pYear & "-" & pMonth  & "-" & pDay && pHour &":" & pMinute & ":" & pSecond) into tRetVal
	return tRetVal
end sqldate

function mergeView pView
	if ".lc" is not in pView then
		put ".lc" after pView
	end if
	-- return the merge of url ("binfile:"& $_SERVER["DOCUMENT_ROOT"]& "/system/application/ha/views/" & pView) -- rabit
	return the merge of url ("binfile:"& gRigA["APPPATH"] & "views/" & pView) ----- rabit
end mergeView

function fileIDToYoutubeID pFile_ID
	rigDbWhere "file_id", pFile_ID
	put rigDbGet("item") into tQuery
	put rigDbRow(1) into tVideoA
	rigDbWhere "item_id", tVideoA["item_id"]
	put rigDbGet("item_format") into tQuery
	repeat with x = 1 to tQuery["numrows"]
		put rigDbRow(x) into tFormatA
		if tFormatA["format_name"] is "Youtube" then
			put tFormatA["url"] into tURL
			exit repeat
		end if
	end repeat
	if tURL is not empty then
		return extracIDFromYoutubeURL(tURL)
	else
		return "nada:" && pFile_ID
	end if
end fileIDToYoutubeID

function getRecord pFileID
	rigDbWhere "file_id", pFileID
	put rigDbGet("item") into tQuery
	put rigDbRow(1) into tItemA
	rigDbWhere "item_id", tItemA["item_id"]
	put rigDbGet("item_format") into tQuery
	repeat with x = 1 to tQuery["numrows"]
		put rigDbRow(x) into tItemA["formats"][x]
	end repeat
	rigDbWhere "item_id", tItemA["item_id"]
	put rigDbGet("channel") into tQuery
	repeat with x = 1 to tQuery["numrows"]
		put rigDbRow(x) into tItemA["channels"][x]
	end repeat
	-- AAG: 2021-06-10: Adding support for fetching categories.
	put tItemA["item_id"] into tItemID 
	rigDbSelect "*"
	rigDbFrom "category_item"
	rigDBWhere "item_id", tItemID
	rigDbJoin "category", "category.category_id = category_item.category_id"
	put rigDbGet() into tQuery
	repeat with x = 1 to tQuery["numrows"]
		put rigDbRow(x) into tItemA["categories"][x]
	end repeat

	return tItemA
end getRecord

function getRelatedContent pA
	repeat for each item k in pA["category"]
		riglogmessage "debug", "k is" && k
		put trim(k) into tTag
		if the number of words in tTag < 1 then
			next repeat
		end if
		rigDbLike "category", tTag
		rigDbWhere "file_id <>", pA["file_id"]
		rigDBWhere "approved_for_public <>", "NO"
		put rigDbGet("item") into tQuery
		rigLogMessage "debug", "getRelatedContent row count:" && trim(k) && tQuery["numrows"]
		repeat with x = 1 to tQuery["numrows"]
			if x > 500 then
				-- prevent large loops
				exit repeat
			end if
			put rigDbRow(x) into tRetValA[x]
			switch
			case "text" is in tRetValA[x]["media_type"]
				put "media-book" into tRetValA[x]["class"]
			break
			case "podcast" is in tRetValA[x]["media_type"]
				put "media-podcast" into tRetValA[x]["class"]
			break
			case "video" is in tRetValA[x]["media_type"]
				put "media-video" into tRetValA[x]["class"]
			break
			case "slides" is in tRetValA[x]["media_type"]
				put "media-slides" into tRetValA[x]["class"]
			break
			default
			put "media-slides" into tRetValA[x]["class"]
			break
		end switch
		end repeat
	end repeat
	return tRetValA
end getRelatedContent

function trim pT
	repeat while char 1 of pT is among the items of format(" ,\r,\t")
		delete char 1 of pT
	end repeat
	repeat while char -1 of pT is among the items of format(" ,\r,\t")
		delete char -1 of pT
	end repeat
	return pt
end trim

function getRelatedTopics pA
	set the itemdel to comma
	
	repeat for each item k in pA["tags"]
		rigDBWhere "approved_for_public <>", "NO"
		put trim(k) into tTag
		if the number of words in tTag < 1 then
			next repeat
		end if
		rigDbLike "tags", tTag
		rigDbWhere "file_id <>", pA["file_id"]
		put rigDbGet("item") into tQuery
		rigLogMessage "debug", "getRelatedTopics:" && trim(k) && tQuery["numrows"]
		repeat with x = 1 to tQuery["numrows"]
			if x > 500 then
				-- prevent large loops
				exit repeat
			end if
			put rigDbRow(x) into tRetValA[x]
		end repeat
	end repeat
	return tRetValA
end getRelatedTopics

function getReviewsForFileID pFileID
	rigDBLike "source", pFileID
	rigDBLike "media_type", "text/review"
	rigDBWhere "approved_for_public <>", "NO"
	rigDBOrderBy "date_created", "DESC" 
	put rigDbGet("item") into tQuery
	repeat with x = 1 to tQuery["numrows"]
		put rigDbRow(x) into tRetValA[x]
	end repeat
	return tRetValA
end getReviewsForFileID

command appendArray @pBigArray, pSmallArray
	put the keys of pBigArray into tKeys
	sort numeric tKeys
	get line -1 of tKeys
	add 1 to it
	put pSmallArray into pBigArray[it]
end appendArray

function randomArrayElement pA, pHowMany
	if pHowMany is not a number then
		put 1 into pHowMany
	end if
	
	put the keys of pA into tKeys
	sort numeric tKeys
	put the number of lines of tKeys into tTotalCount
	if tTotalCount < pHowMany then
		put tTotalCount into pHowMany
	end if
	
	repeat with x = 1 to pHowMany
		put random(the number of lines of tKeys) into tPick
		get line tPick of tKeys
		put pA[it] into tRetValA[x]
		delete line tPick of tKeys
	end repeat
	return tRetValA
end randomArrayElement

# config loading function
# this function is used to load our configuation text files.
function hapConfig pConfigFile
	if there is a file ("/home/devhap/etc/" & pConfigFile & ".conf") then
		put url ("file:/home/devhap/etc/" & pConfigFile & ".conf") into tData
		repeat with x = 1 to the number of lines in tData
			put line x of tData into tLine
			if char 1 of tLine is among the items of "#,/,-" then
				-- escaping possible comments inside the file.
				next repeat
			end if
			if tLine is empty then
				next repeat
			end if
			
			-- entries in the configuration are keyed. Each line is an entry
			-- the first word is the key, the rest the value. Ie:
			-- email andre@andregarzia.com
			
			put word 1 of tLine into tKey
			put word 2 to -1 of tLine into tValue
			put tValue into tRetValA[tKey]
		end repeat
		return tRetValA
	else
		return false
	end if
end hapConfig

function coverForPublication pData
	if the keys of pData is empty then
		-- we passed a file id instead of record
		-- get the record
		put getRecord(pData) into pData
	end if
	
	return ("/media/books/" & pData["file_id"] & "/" &  pData["file_id"] & "_cover_med.jpg")
end coverForPublication


# hapReport is a function to send email reports to a predefined list of emails.
# this function will be used by the API controller to send reports about the database
# and file manipulations from the stack manager applications.
command hapReport pSubject, pReport
	# first let us pick a list of people to notify.
	# this list lives in /home/devhap/etc/notification.conf
	put hapConfig("notification") into tAccountsToNotifyA
	if tAccountsToNotifyA["notify"] is not empty then
  
		rigMailFrom "devhap@dev.himalayanacademy.com", "devHap notification"
		rigMailTo tAccountsToNotifyA["notify"]

		rigMailSubject "[DevHap API Server]" && pSubject

		replace cr with crlf in pReport
		rigMailMessage pReport
		rigSet_sAltMessage pReport

		put rigMailSend() into tMailResult
	end if
	
	# After mailing the report, we log it to a file
	put pReport & cr & cr & "-----------" & cr & cr after url "binfile:/home/devhap/public_html/system/logs/api_usage.log"
	
	return tMailResult
end hapReport

command ct pType
	put header "Content-Type:" && pType
end ct

function mime pFile
	return shell("file --mime -b" && pFile)
end mime

function identifyfile pFile
	return shell("file" && pFile)
end identifyfile

function EbookWebFormatIsAvailable pA
	repeat for each key tK in pA
		if pA[tK]["format_name"] is "web" then
			return true
		end if
	end repeat
	return false
end EbookWebFormatIsAvailable
	

function enumOptionsArray pTable, pField
	put rigDbQuery("SHOW COLUMNS FROM "&pTable&" LIKE  '"&pField&"'") into tQ
	put rigDbRow(1) into tR
	put tR["type"] into tEnumOptions
	replace "enum(" with empty in tEnumOptions
	replace "'" with empty in tEnumOptions
	delete char -1 of tEnumOptions
	split tEnumOptions by comma
	return tEnumOptions
end enumOptionsArray


command logArray pA, pLabel
	logArrayData pA, pLabel
end logArray


command logArrayData pA, pLabel
	put the keys of pA into tKeys
	sort tKeys
	rigLogMessage "debug",pLabel
	repeat for each line tK in tKeys
		if the keys of pA[tK] is not empty then
			rigLogMessage "debug", (tK&":"&&pA[tK])
			logArrayData pA[tK], tK
		end if
		if pA[tK] is empty then
			next repeat
		end if
		rigLogMessage "debug", (tK&":"&&pA[tK])
	end repeat
end logArrayData

command outputEncodedArray pArray
	put the base64encode of the arrayencode of pArray
end outputEncodedArray
	
function decodeArray64 pChunk
	try
		put the arraydecode of the base64decode of pChunk into tA
		return tA
	catch m
		return false
	end try
end decodeArray64

--> from trevor

/**
* Handlers for converting XML to LiveCode arrays and vice versa. 
*
* Provided by Trevor DeVore of Blue Mango Learning Systems.
*/

/**
* \brief Escapes the predefined XML entities in a string.
*
* \param pStr The string to escape the characters in.
*
* \return String
*/
function EscapePredefinedXMLEntities pStr
    replace "&" with "&amp;" in pStr
    replace "<" with "&lt;" in pStr
    replace ">" with "&gt;" in pStr
    replace "'" with "&apos;" in pStr
    replace quote with "&quot;" in pStr
    
    return pStr
end EscapePredefinedXMLEntities


/**
* \brief Unescapes predefined xml entities in a string.
*
* \param pStr The strin to unescape the characters in.
*
* \return String
*/
function UnescapePredefinedXMLEntities pStr
    replace "&amp;" with "&" in pStr
    replace "&lt;" with "<" in pStr
    replace "&gt;" with ">" in pStr
    replace "&apos;" with "'" in pStr
    replace "&quot;" with quote in pStr
    
    return pStr
end UnescapePredefinedXMLEntities


/**
* \brief Helper function for sorting keys of an array based on order in the XML document the array was created from.
*
* \param pArray Array whose keys you want to sort.
* \param pStripMetaKeys By default any meta keys (keys starting with "@") will be stripped. Pass in false to bypass this behavior.
*
* Revolution array keys are never guaranteed to be in order you created them in 
* so we must come up with some other way of maintaining proper sequence. 
* For arrays representing XML, the XML syntax is used (i.e. node[1], node[2], etc.). 
* This handler will sort keys that use this syntax for representing sequence.
*
* \return String
*/
function SortArrayKeysWithXMLOrdering pArray, pStripMetaKeys
   local theKeys
   
   put pStripMetaKeys is not false into pStripMetaKeys
   
   put the keys of pArray into theKeys
   set the itemDelimiter to "["
   sort theKeys numeric by the last item of each -- 1], 2], 3], etc.
   
   if pStripMetaKeys then
      filter theKeys without "@*"
   end if
   
   return theKeys
end SortArrayKeysWithXMLOrdering


/**
* \brief Converts an XML tree into a LiveCode multi-dimensional array.
*
* \param pXML The xml to convert.
* \param pStoreEncodedAs Encoding to use. Must be a value that can be passed to uniDecode. Default is "utf8".
* \param pUseValueKey  By default node values are stored in a key named after the node. This means you can't have a node with attributes and a node value. Pass in true if you want to store node values in a '@value' key. This will allow a key to have both attributes (in @attributes key) and a value (in @value key).
* \param pForceNumerIndexForNodes A comma delimited list of node names that should always have numbered indexes (NODE[index]) added to them. This makes it easier to loop over results that may have 1 or more results.
*
* A nodes attributes will be stored as an array of it's "@attributes" key.
* Node names will retain the sequence information (i.e. node[1], node[2], etc.).
* This information is necessary to determine order that keys should be processed in. Example:
* set the itemDelimiter to "["
* put the keys of theArray into theKeys
* sort theKeys numeric by the last item of each
*
* \return Array
*/
function ConvertXMLToArray pXML, pStoreEncodedAs, pUseValueKey, pForceNumerIndexForNodes
    local theArray,theResult,theRootNode,theTreeID
    local theXMLEncoding
    
    ## Create an XML tree from XML text
    put revCreateXMLTree(pXML, true, true, false) into theTreeID
    
    if theTreeID is an integer then
        ## Determine the encoding of the XML, default to UTF-8
        put matchText(pXML, "<\?xml (.*)encoding=" & quote & "(.*)" & quote & "\?>", versionMatch, theXMLEncoding) into theResult
        if theXMLEncoding is empty then put "utf-8" into theXMLEncoding
        
        ## Now convert to array. 
        ## The 1st dimension has one key which is the name of the root node.
        put revXMLRootNode(theTreeID) into theRootNode
        if theRootNode is not empty and not(theRootNode begins with "xmlerr,") then
            put ConvertXMLNodeToArray(theTreeID, theRootNode, theXMLEncoding, pStoreEncodedAs, pUseValueKey, pForceNumerIndexForNodes) into theArray[theRootNode]
        end if
        
        revDeleteXMLTree theTreeID
    end if
    
    return theArray
end ConvertXMLToArray


/**
* \brief Converts and revXML created XML Tree to an array.
*
* \param pXMLTree The xml tree id.
* \param pStoreEncodedAs See docs for ConvertXMLToArray.
* \param pUseValueKey See docs for ConvertXMLToArray.
* \param pForceNumerIndexForNodes See docs for ConvertXMLToArray.
*
* See docs for ConvertXMLToArray.
*
* \return Array
*/
function ConvertXMLTreeToArray pXMLTree, pStoreEncodedAs, pUseValueKey, pForceNumerIndexForNodes
    return ConvertXMLToArray(revXMLText(pXMLTree), pStoreEncodedAs, pUseValueKey, pForceNumerIndexForNodes)
end ConvertXMLTreeToArray


/**
* \brief Converts a multi-dimensional array to an XML tree.
*
* \param pArray The array to convert.
* \param pArrayEncoding Encoding used in the array. Must be a value that can be passed to uniEncode. Default is the current platform encoding.
* \param pStoreEncodedAs Encoding to use. Must be a value that can be passed to uniDecode. Default is "utf8".
*
* The array should consist of one key in the 1st dimension. This key becomes the root node in the XML tree.
* Attributes of a node should be stored as an array in an @attributes key. 
* Sequence information for multiple nodes with the same name should be included in the node name using brackets (i.e. node[1], node[2], node[3]).
*
* \return XML Tree id (integer) or error message.
*/
function ConvertArrayToXML pArray, pArrayEncoding, pStoreEncodedAs
    local theError,theRootNode,theXML,theXMLTree
    
    ## if pArrayEncoding is empty then current platform encoding is assumed
    if pStoreEncodedAs is empty then put "UTF-8" into pStoreEncodedAs
     
    ## Create XML for root node. Note that we take extra steps in order to support
    ## converting an array that only represents part of a tree rather than the entire tree.
    ## In this case there may be multiple nodes at the root level.
    put line 1 of the keys of pArray into theRootNode 
    set the itemDelimiter to "["
    put "<" & item 1 of theRootNode & "/>" into theXML
     
    ## Create XML needed to create tree
    put format("<?xml version=\"1.0\" encoding=\"%s\"?>%s", \
            pStoreEncodedAs, theXML) into theXML
    put revCreateXMLTree(theXML, true, true, false) into theXMLTree
     
    if theXMLTree is an integer then
        ## Loop over all nodes at root level
        put false into stripMetaKeys
        put SortArrayKeysWithXMLOrdering(pArray, stripMetaKeys) into theNodes
         
        ## Create tree using helper function
        repeat for each line theNode in theNodes
            ConvertArrayDimensionToXML pArray[theNode], theXMLTree, slash & theNode, \
                    pArrayEncoding, pStoreEncodedAs
            put the result into theError
             
            if theError is not empty then exit repeat
        end repeat
        
        if theError is not empty then
            ## something went wrong, clean bad tree
            revDeleteXMLTree theXMLTree
        end if
    else
        put theXMLTree into theError
    end if
     
    if theError is not empty then
        return theError
    else
        return theXMLTree
    end if
end ConvertArrayToXML
 
 
 /**
* \brief Helper function for ConvertArrayToXML.
*
* Converts the multi-dimensional array pArray to nodes in pTreeID. Calls itself recursively.
*
* \return Error message.
*/
command ConvertArrayDimensionToXML pArray, pTreeID, pNode, pArrayEncoding, pStoreEncodedAs
    local theError,theKey,theKeys,theNode
    
    ## A workaround for fact that Revolution does not return
    ## keys in the order we created them
    put false into stripMetaKeys
    put SortArrayKeysWithXMLOrdering(pArray, stripMetaKeys) into theNodes
    
    ## Arrays might have sequencing info in name 
    ## (i.e. step[1], step[2], ... )
    set the itemDelimiter to "["
    
    repeat for each line theFullNode in theNodes
        put item 1 of theFullNode into theNode
         
        ## Look for attributes. These will be added as attributes to pNode.
        if theNode is "@attributes" or theNode is "@attr" then
            repeat for each line theKey in the keys of pArray[theFullNode]
                revSetXMLAttribute pTreeID, pNode, theKey, \
                        EncodeString(pArray[theFullNode][theKey], \
                        pArrayEncoding, pStoreEncodedAs)
                if the result begins with "xmlerr," then 
                    put the result && "(setting attribute" && theKey && "for node" && pNode & ")" into theError
                end if
                
                if theError is not empty then exit repeat
            end repeat
            
        else if theNode is "@value" then
            ## This XML tree is using complex structure. Node is the value of the parent node
            revPutIntoXMLNode pTreeID, pNode, EncodeString(pArray[theFullNode], pArrayEncoding, pStoreEncodedAs)
            if the result begins with "xmlerr," then
                put the result && "(adding child node" && theNode && "to node" && pNode & ")" into theError
            end if
            
        else
            if the keys of pArray[theFullNode] is not empty then
                ## Node has children. Add node to XML tree then call self recursivly to create children nodes. 
                revAddXMLNode pTreeID, pNode, theNode, empty
                if the result begins with "xmlerr," then
                    put the result && "(adding node" && theNode & ")" into theError
                end if
                
                if theError is empty then
                    ConvertArrayDimensionToXML pArray[theFullNode], pTreeID, pNode & slash & theFullNode, \
                            pArrayEncoding, pStoreEncodedAs
                    put the result into theError
                end if
            else
                ## Node has no children but possibly a value. Create node and add value (which may be empty).
                revAddXMLNode pTreeID, pNode, theNode, \
                        EncodeString(pArray[theFullNode], pArrayEncoding, pStoreEncodedAs)
                if the result begins with "xmlerr," then
                    put the result && "(adding child node" && theNode && "to node" && pNode & ")" into theError
                end if
            end if
        end if 
         
        if theError is not empty then exit repeat
    end repeat
    
    return theError
end ConvertArrayDimensionToXML
 

/**
* \brief Helper function for ConvertXMLToArray.
*
* Converts an XML node to a multi-dimensional array. Calls itself recursively.
*
* \return Array
*/
function ConvertXMLNodeToArray pTreeID, pNode, pXMLTreeEncoding, pStoreEncodedAs, pUseValueKey, pForceNumerIndexForNodes
    local theArrayA,theAttributes,theChildNode,theKey
     
    ## Look for attributes of the node. Store as array in "@attributes" key
    put revXMLAttributes(pTreeID, pNode, tab, cr) into theAttributes
    if theAttributes is not empty then
        put EncodeString(theAttributes, pXMLTreeEncoding, pStoreEncodedAs) into theAttributes
        split theAttributes by cr and tab -- create array
        put theAttributes into theArrayA["@attributes"]
    end if
     
    ## Look for children nodes. 
    set the itemDelimiter to slash
    put revXMLFirstChild(pTreeID, pNode) into theChildNode
    if theChildNode is empty or theChildNode begins with "xmlerr," then
        put EncodeString(revXMLNodeContents(pTreeID, pNode), pXMLTreeEncoding, pStoreEncodedAs) into theValue
        if word 1 to -1 of theValue is empty and the keys of theArrayA is not empty then
            ## Empty node that has attributes
            return theArrayA
        else if pUseValueKey then
            ## Force value into @value
            put theValue into theArrayA["@value"]
            return theArrayA
        else
            ## Single Node with value: Return value. Attributes are ignored.
            return theValue
        end if
    else
        ## Child nodes were found. Recursively call self and store result in array.
        set the wholeMatches to true
        replace comma with cr in pForceNumerIndexForNodes
        repeat while theChildNode is not empty and not (theChildNode begins with "xmlerr,")
            put the last item of theChildNode into theKey
            if theKey is among the lines of pForceNumerIndexForNodes then
                ## Oops, key that needs index doesn't have one. Only 1 entry in XML.
                put "[1]" after theKey
            end if      
            put ConvertXMLNodeToArray(pTreeID, theChildNode, pXMLTreeEncoding, pStoreEncodedAs, pUseValueKey, \
                    pForceNumerIndexForNodes) into theArrayA[theKey]
            put revXMLNextSibling(pTreeID, theChildNode) into theChildNode
        end repeat
         
        return theArrayA
    end if
end ConvertXMLNodeToArray
 
 
/**
* \brief Helper function for converting the encoding of strings when converting to and from XML.
*
* \return String
*/
function EncodeString pString, pInEncoding, pOutEncoding
   ## convert utf-8 to utf8 for uniencode/decode
   replace "-" with empty in pInEncoding
   replace "-" with empty in pOutEncoding
   
   if pInEncoding is not empty then
      -- if pOutEncoding is empty then pString will be converted to the current platform encoding
      return uniDecode(uniEncode(pString, pInEncoding), pOutEncoding)
   else
      if pOutEncoding is not empty then
         -- if pInEncoding is empty then pString is assumed to be in the current platform encoding
         return uniDecode(uniEncode(pString, pInEncoding), pOutEncoding)
      else
         return pString
      end if
   end if
end EncodeString


function xmlAttributesToArray pTreeID pNode
	put revXMLAttributes(pTreeID,pNode,":",return) into tBuf
	if "xmlerr" is in tBuf then
		return empty
	else
		split tBuf by return and ":"
		return tBuf
	end if
end xmlAttributesToArray

function byline pRecordA
	switch
		case "video" is in pRecordA["media_type"]
			put pRecordA["contributor"] into tRetVal
		break
		case "art/painting" is in pRecordA["media_type"]
		case "art/drawing" is in pRecordA["media_type"]
		case "art/vector" is in pRecordA["media_type"]
			put pRecordA["artists"] into tRetVal
		break
		case "art/photograph" is in pRecordA["media_type"]
		case "slideshow/external" is in pRecordA["media_type"]
		case "slideshow/galleria" is in pRecordA["media_type"]
			put pRecordA["photographer"] into tRetVal
		break
		case "book" is in pRecordA["media_type"]
			put pRecordA["author"] into tRetVal
		break
		case "audio/inspiredtalk" is in pRecordA["media_type"]
			put pRecordA["author"] into tRetVal
		break
		case "audio/chant" is in pRecordA["media_type"]
		case "audio/song" is in pRecordA["media_type"]
		case "audio/instrumental" is in pRecordA["media_type"]
		case "audio/shum" is in pRecordA["media_type"]
			put pRecordA["artists"] into tRetVal
		break
	end switch
	
	if tRetVal is empty then
		return empty
	else
		return "By" && tRetVal
	end if
end byline

function kadavulVigilsDoneToDate
# converted from Siddhanathaswami's CGI
# By Brahmanathaswami
# this is used on the Kadavul info page
  put "3/11/73 11:00 PM" into startDate
  put (the date && the time) into endDate		
  convert(startDate) to seconds
  put it into startDateSeconds
  convert(endDate) to seconds
  put it into endDateSeconds
  
  put endDateSeconds - startDateSeconds into secondsDiff
  
  put 60*60*3 into secondsIn3Hours
  
  put trunc(secondsDiff/secondsIn3Hours) into numVigils
  
  return numVigils
end kadavulVigilsDoneToDate

function emitLinkedList pA
	put the keys of pA into tKeys
	sort numeric tKeys
	repeat for each line x in tKeys
		put format("<li><a href=\"%s\">%s</a></li>\n", pA[x]["src"], pA[x]["title"]) after tBuf
	end repeat
	delete char -1 of tBuf
	return tBuf
end emitLinkedList	

function makeArray
	repeat with x = 1 to the paramcount step 2
		put param(x + 1) into tA[param(x)]
	end repeat
	return tA
end makeArray 

function makeValidSelector tSelector
	put "-,_" into tInValids
	repeat for each item x in tInValids
		replace x with "" in tSelector
	end repeat 
	return tSelector
end makeValidSelector

function getConcurrentDatesTimes pNextWebinarInHawaii
	-- put url "file:/home/devhap/public_html/system/application/ha/libraries/world-time-zones.txt" into tZones -- rabit
   put url "file:" & gRigA["APPPATH"] & "libraries/world-time-zones.txt" into tZones ------- rabit

	set the itemdel to "|"
	put item 1 of tZones into tTargetCities
			
	######## CONVERT FUTURE TIME TO CONCURRENT FUTURE TIMES ##############
	# Generate a list of concurrent dates and times in other countries and cities
	# for a declared future Hawaii (HST;  UTC1000) date and time

	convert pNextWebinarInHawaii to seconds 

	# get the current time in Hawaii; convert to seconds

	put "America/Honolulu" into $TZ 
	put shell("date -R") into tCurrentTimeInHawaii
	convert tCurrentTimeInHawaii to seconds	

	# substract current from future and get the timeUntilNextWebinar increment

	put (pNextWebinarInHawaii - tCurrentTimeInHawaii) into tFutureIncrement

	# get a list of times now for several cities

	repeat for each line x in tTargetCities
		
			put x into $TZ # or whatever time zone(s) you want to show
			put shell("date -R") into tDTstring	
			# add the increment
			convert tDTstring to seconds
			put (tDtstring + tFutureIncrement) into tFutureDTstring
			convert tFutureDTstring to internet date
			put x & ": " & tFutureDTstring & "<br />" after tTimesInOtherCities
	end repeat
	
	return tTimesInOtherCities
end getConcurrentDatesTimes

		