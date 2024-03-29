script ""

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


global gData
global sXML
global sXA

/*

CMS Library

Author: Andre Alves Garzia (andre@andregarzia.com)
30/01/12

License: BSD 

*/


# LOGGING
rigLogMessage "debug", "CMS Library Loaded"

# DECLARE LOCAL VARIABLES
local sCMSDataFolder
put "/home/devhap/public_html/html" into sCMSDataFolder

command rigRunInitialCMSConfig
	rigLoaderLoadLibrary "markdown"
	rigLoaderLoadLibrary "arraytools"
	rigLoaderLoadLibrary "utils"
	rigLoaderLoadLibrary "pagemetadata"
end rigRunInitialCMSConfig

function cmsDataFolder
	return sCMSDataFolder
end cmsDataFolder

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

function cmsFileType pFile
	set the itemdel to "."
	
	put item -1 of pFile into tExtension
	
	switch tExtension
		case "html"
			return "HTML file"
		break
		case "xhtml"
			return "XHTML file"
		break
		case "xml"
			return "XML file"
		break
		case "md"
			return "Markdown file"
		break
		default
		return (toUpper(tExtension) && "file")
	end switch
end cmsFileType

function cmsFile pFile
	if there is not a file (sCMSDataFolder & pFile) then
		rigLogMessage "error","CMS file not found:" && pFile
		return empty
	end if
	
	put sCMSDataFolder & pFile into tFilePath
	
	switch cmsFileType(pFile)
		case "Markdown file"
			return markdown(tFilePath)
		break
		default
		return url ("binfile:" & tFilePath)
	end switch
end cmsFile

function extractPromotedCollectionsModule pNode
	put revXMLNodeContents(sXML, (pNode & "/title")) into tRetValA["title"]
	put revXMLNumberOfChildren(sXML, pNode,"collection",1) into tNumberOfCollections
	repeat with c = 1 to tNumberOfCollections
		put pNode & "/collection["&c&"]" into tCollectionNode
		put revXMLNodeContents(sXML, (tCollectionNode & "/title")) into tRetValA["collections"][c]["title"]
		put revXMLNodeContents(sXML, (tCollectionNode & "/thumbnail")) into tRetValA["collections"][c]["thumbnail"]
		put revXMLNodeContents(sXML, (tCollectionNode & "/cta")) into tRetValA["collections"][c]["cta"]
		put revXMLAttribute(sXML, (tCollectionNode & "/cta"), "url") into tRetValA["collections"][c]["cta_link"]
		if "xmlerr" is in tRetValA["collections"][c]["cta_link"] then
			put "#" into tRetValA["collections"][c]["cta_link"]
		end if
		if "#" is in tRetValA["cta_link"] then
			get revXMLAttribute(sXML, (pNode & "/cta"), "file_id")
			if "xmlerr" is not in it then
				put "/view/" & it into tRetValA["cta_link"]
			end if
		end if
		put revXMLNumberOfChildren(sXML, (tCollectionNode & "/links"),"link",1) into tNumberOfLinks
		repeat with l = 1 to tNumberOfLinks
			put revXMLNodeContents(sXML, (tCollectionNode & "/links/link["&l&"]")) into tRetValA["collections"][c]["links"][l]["title"]
			put revXMLAttribute(sXML, (tCollectionNode & "/links/link["&l&"]"), "url") into tRetValA["collections"][c]["links"][l]["url"]
		end repeat
	end repeat
	return tRetValA
end extractPromotedCollectionsModule

function extractTabbedContentModule pNode
	rigLogMessage "debug", "Begin extract tabbed content"
	put revXMLNodeContents(sXML, (pNode & "/title")) into tRetValA["title"]
	put revXMLNumberOfChildren(sXML, pNode,"tab",1) into tNumberOfTabs
	rigLogMessage "debug", "number of tabs:" && tNumberOfTabs
	repeat with c = 1 to tNumberOfTabs
		put pNode & "/tab["&c&"]" into tTabNode
		put revXMLAttribute(sXML, tTabNode, "title") into tRetValA["tabs"][c]["title"]
		rigLogMessage "debug", "Tab:" && tRetValA["tabs"][c]["title"]
		put revXMLChildNames(sXML, tTabNode,comma,,true) into tTabContent
		put 0 into y
		put empty into tThisTabContentA
		repeat for each item tItem in tTabContent
			set the itemdel to "["
			put item 1 of tItem into tNodeName
			rigLogMessage "debug", "tab node:" && tNodeName
			set the itemdel to comma
			switch tNodeName
				case "search"
					-- do search
					rigDbWhere "approved_for_public", "YES"
					repeat for each line thisLine in revXMLAttributes(sXML,(tTabNode & "/" & tItem),comma,return)
						put item 1 of thisLine into tKey
						put item 2 of thisLine into tValue
						rigLogMessage "debug", "search for" && tKey &&"->" && tValue
						rigDbWhere (tKey && "LIKE"), ("%" & tValue & "%")
					end repeat
					rigDbLimit 100
					put rigDbGet("item") into tQ
					rigLogMessage "debug", "results:" && tQ["numrows"]
					repeat with x = 1 to tQ["numrows"]
						put rigDbRow(x) into tThisTabContentA[y+x]
					end repeat
					put x+y into y
				break
				case "item"
					get revXMLAttribute(sXML,(tTabNode & "/" & tItem),"file_id" )
					rigDbWhere "file_id", it
					put rigDbGet("item") into tQ
					add 1 to y
					put rigDbRow(1) into tThisTabContentA[y]
				break
			end switch
		end repeat
		put tThisTabContentA into tRetValA["tabs"][c]["content"]
	end repeat
	rigLogMessage "debug", "End extract tabbed content"
	return tRetValA
end extractTabbedContentModule

function extractSquareSliderModule pNode
	put revXMLNodeContents(sXML, (pNode & "/title")) into tRetValA["title"]
	put revXMLNodeContents(sXML, (pNode & "/cta")) into tRetValA["cta"]
	put revXMLAttribute(sXML, (pNode & "/cta"), "url") into tRetValA["cta_link"]
	if "xmlerr" is in tRetValA["cta_link"] then
		put "#" into tRetValA["cta_link"]
	end if
	if "#" is in tRetValA["cta_link"] then
		get revXMLAttribute(sXML, (pNode & "/cta"), "file_id")
		if "xmlerr" is not in it then
			put "/view/" & it into tRetValA["cta_link"]
		end if
	end if
	put revXMLNumberOfChildren(sXML, (pNode & "/slides"),"item",1) into tNumberOfItems
	repeat with c = 1 to tNumberOfItems
		put pNode & "/slides/item["&c&"]" into tItemNode
		put revXMLNodeContents(sXML, (tItemNode & "/image")) into tRetValA["items"][c]["image"]
		put revXMLNodeContents(sXML, (tItemNode & "/caption")) into tRetValA["items"][c]["caption"]
		put revXMLNodeContents(sXML, (tItemNode & "/link")) into tRetValA["items"][c]["link"]
		put revXMLAttribute(sXML, (tItemNode & "/link"), "url") into tRetValA["items"][c]["link_link"]
		if "xmlerr" is in tRetValA["items"][c]["link_link"] then
			put "#" into tRetValA["items"][c]["link_link"]
		end if
	end repeat
	put emitSquareSliderModuleHTML(tRetValA["items"]) into tRetValA["html"]
	return tRetValA	
end extractSquareSliderModule

function emitSquareSliderModuleHTML pListA
	repeat with x = 1 to the number of lines in the keys of pListA
		put format("<figure class=\"slider-item\">") after tRetVal
		put format("<a href=\"%s\"><div class=\"img-crop\">", pListA[x]["link"]) after tRetVal
		put format("<img src=\"%s\" alt=\"%s\" />", pListA[x]["image"], pListA[x]["caption"]) after tRetVal
		put format("</div></a>") after tRetVal
		put format("<figcaption class=\"caption\">%s</figcaption>",pListA[x]["caption"]) after tRetVal
		put format("</figure>") after tRetVal
	end repeat
	return tRetVal	
end emitSquareSliderModuleHTML

function emitTabbedContentModuleHTML pTabsA
	rigLogMessage "debug", "begin emit tabbed content module HTML"
	if the keys of pTabsA is empty then
		rigLogMessage "debug", "no tabbed content"
		return empty
	end if
	-- emit titles
	put format("<section class=\"tabbed-content-container browse\"><h2 class=\"h2\">Browse Our Books</h2><ul class=\"tabs\">") into tRetVal
	repeat with x = 1 to the number of lines in the keys of pTabsA
		rigLogMessage "debug", "found tab:" && pTabsA[x]["title"]
		if x is 1 then
			put format("<li class=\"active\"><a href=\"#\">%s</a></li>", pTabsA[x]["title"]) after tRetVal
		else
			put format("<li><a href=\"#\">%s</a></li>", pTabsA[x]["title"]) after tRetVal
		end if
	end repeat
	put format("</ul><div class=\"tabbed-content tabulate\">") after tRetVal
	-- Emit Tabs
	repeat with x = 1 to the number of lines in the keys of pTabsA
		put pTabsA[x] into pTabA
		-- Emit Header thing for tab
		put format("<div class=\"ebooks\"><ul class=\"archives-pagination\"><li class=\"arrow-prev\"><a href=\"#\">Previous</a></li><li class=\"arrow-next\"><a href=\"#\">Next</a></li></ul><div class=\"slidecontrol-select\"></div><div class=\"paginate\">") after tRetVal
	
		-- Emit groups (for pagination)
		rigLogMessage "debug","number of items in tab '" && pTabsA[x]["title"] && "':" && the number of lines in the keys of pTabA["content"]
		repeat with y = 1 to the number of lines in the keys of pTabA["content"] step 4
				if pTabA["content"][y]["file_id"] is empty then
					next repeat
				end if
				put format("<div class=\"browse-group\">") after tRetVal -- Begin page
			
				-- each item
				repeat with k = 0 to 3
					put pTabA["content"][y+k] into pTabItemA
					if pTabItemA["file_id"] is empty then
						next repeat
					end if
					put format("<div class=\"browse-item\">") after tRetVal	
					put format("<a href=\"/view/%s\"><img src=\"/media/books/%s/%s_cover_thm.jpg\" alt=\"Image of %s\"></img></a>",pTabItemA["file_id"], pTabItemA["file_id"], pTabItemA["file_id"], pTabItemA["title"]) after tRetVal
					put "<hgroup>" after tRetVal
					put format("<h5 class=\"title\"><a href=\"/view/%s\">%s</a></h5>", pTabItemA["file_id"], pTabItemA["title"]) after tRetVal
					put format("<h6 class=\"subtitle\">%s</h6>", pTabItemA["sub_title"]) after tRetVal
					put "</hgroup>" after tRetVal
					put format("<a class=\"action\" href=\"/view/%s\">Read Online</a>", pTabItemA["file_id"]) after tRetVal
				    put "</div>" after tRetVal
				end repeat
				put "</div>" after tRetVal -- end browser group
			    
		end repeat
		put "</div></div>" after tRetVal -- end paginate and tab
	end repeat
	put "</section>" after tRetVal -- end section
	rigLogMessage "debug", tRetVal
	return tRetVal
end emitTabbedContentModuleHTML

function emitLinkList pListA
	repeat with x = 1 to the number of lines in the keys of pListA
		put format("<li><a href=\"%s\">%s</a></li>\n", pListA[x]["url"], pListA[x]["title"]) after tRetVal
	end repeat
	return tRetVal
end emitLinkList

function emitYoutubeVideo pW, pH, pVideoID, pStyle
	if pW is empty then
		put 560 into pW
	end if
	if pH is empty then
		put 315 into pH
	end if
	if pStyle is not empty then
		put "style=" & quote & pStyle & quote into pStyle
	end if
	put format("<iframe width=\"%s\" height=\"%s\" src=\"http://www.youtube.com/embed/%s\" frameborder=\"0\" %s allowfullscreen></iframe>", pW, pH, pVideoID, pStyle) into tRetVal
	return tRetVal
end emitYoutubeVideo

function emitVideo pNode
	put revXMLAttribute(sXML, pNode, "width") into tWidth
	put revXMLAttribute(sXML, pNode, "height") into tHeight
	put revXMLAttribute(sXML, pNode, "file_id") into tFileID
	put revXMLAttribute(sXML, pNode, "style") into pStyle
	if "xmlerr" is in pStyle then
		put empty into pStyle
	end if
	return emitYoutubeVideo(tWidth, tHeight, fileIDToYoutubeID(tFileID), pStyle)
end emitVideo

function textcut pText, pNumOfWords
	if the number of words in pText <= pNumOfWords then
		return pText
	else
		return word 1 to pNumOfWords of pText & "..."
	end if
end textcut

function emitSearchResultForMediaCatalogPage pA
	put the number of lines in the keys of pA into tNumResults
	put tNumResults div 3 into tNumRows
	if tNumResults mod 3 > 0 then 
		add 1 to tNumRows
	end if
	put 0 into c
	repeat with x = 1 to tNumRows
		put format("<div class=\"row\">\n") after tBuf
		repeat 3 times
			add 1 to c
			if the keys of pA[c] is not empty then
				put format("\t<div class=\"column\">\n") after tBuf
				switch pA[c]["media_type"]
					case "art/drawing"
						put format("\t\t<a href=\"/view/%s\"><img src=\"/media/art/drawing/%s/%s_sml.jpg\" alt=\"Image of...\" /></a>\n", pA[c]["file_id"],pA[c]["file_id"], pA[c]["file_id"]) after tBuf
					break
					case "art/vector"
						put format("\t\t<a href=\"/view/%s\"><img src=\"/media/art/vector/%s/%s_sml.jpg\" alt=\"Image of...\" /></a>\n", pA[c]["file_id"],pA[c]["file_id"], pA[c]["file_id"]) after tBuf
					break
					case "art/painting"
						put format("\t\t<a href=\"/view/%s\"><img src=\"/media/art/painting/%s/%s_sml.jpg\" alt=\"Image of...\" /></a>\n", pA[c]["file_id"],pA[c]["file_id"], pA[c]["file_id"]) after tBuf
					break
					case "video/pubdesk" 
					case "video/travel" 
					case "video/teaching" 
					case "video/ritual" 
					case "video/building" 
					case "video/talk" 
					case "video/news"
						--background-image: url("http://i4.ytimg.com/vi/cuWUwfNzWog/hqdefault.jpg");
						put format("\t\t<a href=\"/view/%s\"><img src=\"http://i4.ytimg.com/vi/%s/hqdefault.jpg\" alt=\"Image of...\" /></a>\n", pA[c]["file_id"], fileIDToYoutubeID(pA[c]["file_id"])) after tBuf
					break
					case "text/book"				
					case "text/booklet"
						put format("\t\t<a href=\"/view/%s\"><img src=\"/media/books/%s/%s_cover_med.jpg\" alt=\"Image of...\" /></a>\n", pA[c]["file_id"],pA[c]["file_id"], pA[c]["file_id"]) after tBuf
					break
				end switch
				--put format("<img src=\"/html/manager/templates/FPO/img-book-1.jpg\" alt=\"Image of...\" />\n") after tBuf
				put format("\t\t<h3 class=\"title\"><a href=\"/view/%s\">%s</a></h3>\n",  pA[c]["file_id"], pA[c]["title"]) after tBuf
				# put format("\t\t<p><a style=\"color: black\" href=\"/view/%s\">%s</a></p>\n", pA[c]["file_id"], textcut(pA[c]["description"],50)) after tBuf
				# Brahma: 2012-07-14: the base text color of the site is not solid black and the description should not be linked. So I changed this to:
				# But we can adjust the above line to 
				put format("\t\t<p>%s</p>\n", textcut(pA[c]["description"],18)) after tBuf
				put format("\t</div>\n") after tBuf
			end if
		end repeat
		put format("</div>\n") after tBuf
		add 1 to c
	end repeat
	return tBuf
end emitSearchResultForMediaCatalogPage

function emitGalleria pNode
	put revXMLAttribute(sXML, pNode, "width") into tWidth
	put revXMLAttribute(sXML, pNode, "height") into tHeight
	put revXMLAttribute(sXML, pNode, "style") into gData["style"]
	put revXMLAttribute(sXML, pNode, "file_id") into tFileID
	put getRecord(tFileID) into tRecordA
	set the itemdel to "-"
	put item 1 of tRecordA["date_created"] into tYear
	put tWidth into tOptions[width]
	put tHeight into tOptions["height"]
	put "true" into tOptions["imageCrop"]
	put "false" into tOptions["thumbCrop"]
	put "true" into tOptions["imagePan"]
	put "100" into tOptions["transitionSpeed"] 
	
	put tWidth into gData["width"]
	put tHeight into gData["height"]
	
	put format("media/slideshows/%s/%s", tYear, tFileID) into tPath

	if there is a file ("/home/devhap/public_html/" & tPath & "/galleriaData.js") then
		delete file ("/home/devhap/public_html/" & tPath & "/galleriaData.js")
	end if
	
	# SKTS: March, 14, 2012 the above if statement to delete the galleriaData.js 
	# is not working, but there is no need for it. The galleria plug-in rigGalleriaData
	# take, as parameter # 6 the option to replace the existing galleriaData.js file
	# by default it is set to "FALSE"
	# But I am setting it to TRUE because the slideshow are "stuck" on their
	# last width and height settings 

	put rigGalleriaData(tPath,tOptions,,,FALSE,TRUE) into gData["slideShow"]
	
	put rigLoadView("media/galleria-load-assets", TRUE) into tRetVal
	
	return tRetVal
end emitGalleria

function cmsParseXMLDataFile pFile
	if there is not a file (sCMSDataFolder & pFile) then
		rigLogMessage "error", "CMS Can't load XML data file. File not found:" && sCMSDataFolder & pFile
		return empty
	end if
	
	put (sCMSDataFolder & pFile) into tFilePath
	
	updatePageMetadataIfPathOnDiskChanged pFile
	
	put revCreateXMLTreeFromFile(tFilePath, true, true, false) into sXML
	
	if sXML is not a number then
		rigLogMessage "error", "CMS Data file is not valid XML." && pFile && sXML
		return empty
	end if
	
	put revXMLNumberOfChildren(sXML, "/data","module",1) into tNumberOfChildren
	
	repeat with x = 1 to tNumberOfChildren
		put "/data/module[" & x & "]" into tModuleNode
		put revXMLAttribute(sXML, tModuleNode, "name") into tModuleName
		# extract data
		put revXMLFirstChild(sXML, tModuleNode) into tNode
		
			switch tModuleName
				case "Links Module"
				case "Promoted Collections Module"
					put extractPromotedCollectionsModule(tModuleNode) into tRetValA[tModuleName]
					next repeat
				break
				case "Square Slider Module"
					put extractSquareSliderModule(tModuleNode) into tRetValA[tModuleName]
					next repeat
				break
				case "Tabbed Content Module"
					put extractTabbedContentModule(tModuleNode) into tRetValA[tModuleName]
					--put emitTabbedContentModuleHTML(tRetValA[tModuleName]["tabs"]) into ecaA
					next repeat
				break
				case "Featured Item Module"
					put revXMLAttribute(sXML, (tModuleNode & "/media"), "file_id") into tFileID
					put byline(getRecord(tFileID)) into tRetValA[tModuleName]["author"]
					#SKTS: Get title and description
					put getRecord(tFileID) into tRecordA
					put tRecordA["title"] into tRetValA[tModuleName]["title"]
					put tRecordA["description"] into tRetValA[tModuleName]["description"]
				break
			end switch
				
		set the itemdel to slash
		repeat while tNode is not empty
			put revXMLNumberOfChildren(sXML, tNode,"",1) into tNumberOfNodeChildren
			put item -1 of tNode into tNodeName
			try
				put revXMLAttribute(sXML, tNode, "type") into tNodeType
				if "xmlerr, can't find attribute" is in tNodeType then
					put "no type" into tNodeType
				end if
			catch n
				put "no type" into tNodeType
				-- if it has no type, then, check for file_id attribute. We can infer the type based on file_id
			end try
			
			if tNodeType is "no type" then
				put revXMLAttribute(sXML, tNode, "file_id") into tFileID
				if "xmlerr, can't find attribute" is not in tFileID then
					put getRecord(tFileID) into tRecordA
					switch
						case "video" is in tRecordA["media_type"]
							put "video" into tNodeType
						break
						case "slideshow/galleria" is in tRecordA["media_type"]
							put "galleria" into tNodeType
						break
					end switch
				end if
			end if
			
			switch tNodeType
				case "lorempixel"
					put revXMLAttribute(sXML, tNode, "width") into tWidth
					put revXMLAttribute(sXML, tNode, "height") into tHeight
					put revXMLAttribute(sXML, tNode, "category") into tCategory
					put lorempixel(tCategory, tWidth, tHeight) into tRetValA[tModuleName][tNodeName]
				break
				case "video"
					put emitVideo(tNode) into tRetValA[tModuleName][tNodeName]
				break
				case "galleria"
					put emitGalleria(tNode) into tRetValA[tModuleName][tNodeName]
				break
				case "link"
					if "xmlerr" is not in revXMLAttribute(sXML, tNode, "file_id") then
						put "/view/" & revXMLAttribute(sXML, tNode, "file_id") into tRetValA[tModuleName][tNodeName&"_link"]
					else
						put revXMLAttribute(sXML, tNode, "url") into tRetValA[tModuleName][tNodeName&"_link"]
					end if
					put revXMLNodeContents(sXML, tNode) into tRetValA[tModuleName][tNodeName]
				break
				default
					if tNumberOfNodeChildren is 0 then
						put revXMLNodeContents(sXML, tNode) into tRetValA[tModuleName][tNodeName]
					else
					
					end if
				break
			end switch
			rigLogMessage "debug", (tModuleName && "-->" && tNodeName && "("&tNodeType&") -->" && tRetValA[tModuleName][tNodeName])
			
			put revXMLNextSibling(sXML, tNode) into tNode
		end repeat
	end repeat
	
	revDeleteXMLTree sXML
	
	return tRetValA
end cmsParseXMLDataFile
	