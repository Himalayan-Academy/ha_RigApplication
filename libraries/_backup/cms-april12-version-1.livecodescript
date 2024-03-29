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
	