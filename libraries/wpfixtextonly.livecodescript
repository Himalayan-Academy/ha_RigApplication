script "wp-fix-text-only"

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


# LOGGING
rigLogMessage "debug", "Wordpress XML-RPC Library Loaded"

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialwpConfig
    --Run initial configuration procedures. Don't remove this handler, even if it does nothing.'
	rigLoaderLoadLibrary "arraytools"
	rigLoaderLoadLibrary "xmlrpc"
end rigRunInitialwpConfig

--> Wordpress Suite

function wpGetUsersBlogs pUser, pPassword
	return callXMLRPC("wp.getUsersBlogs", pUser, pPassword)
end wpGetUsersBlogs

function wpGetPosts pBlogID, pUser, pPassword, pFilterA
	return callXMLRPC("wp.getPosts", pBlogID, pUser, pPassword)
end wpGetPosts

# First parse for a galleria post; get 1st pix and 1st caption from the var data 
# then pick the <p> content at the end if there is any.


function parseForImage pContent
		If pContent contains "var data" then # it is a galleria slideshow
	      put	 line ( lineOffset ("image:",pContent) ) of pContent into tImagePath
	      set the itemdel to "/"
	      delete item 1 of tImagePath
	      replace "'," with "" in tImagePath
	      put "/" before tImagePath
	      return  tImagePath
			else # we have some other kind of content; 
				  # find the first image; assume simple html image tag is there for sure:      
				put	 line ( lineOffset ("<img",pContent) ) of pContent into tImageTagString
				delete word 1 of tImageTagString
				delete word -1 of tImageTagString
				split tImageTagString with space and "="
				put the keys of tImageTagString				
				Replace quote with empty in   tImageTagString["src"] 
				return tImageTagString["src"] 			      	
		end if
end parseForImage

function parseForCaption pContent
		If pContent contains "var data" then # dig for the first description. It could be empty that's OK.
	      # get the line number of the first image closing JSON:
	      put  lineOffset ("},",pContent) into tEndOfFirstImage    
	      # test for description in two possible lines
	      if (line tEndOfFirstImage of pContent contains "description") or (line (tEndOfFirstImage-1) of pContent contains "description")  then
		  put	 line ( lineOffset ("description",pContent) ) of pContent into tCaption
	      set the itemdel to "'"
	      delete item 1 of tCaption
	      replace "'," with "" in tCaption
	      if char -1 of tCaption ="'" then delete char -1 of tCaption
	      replace "\" with "" in tCaption	  # undo escaped JSON chars
	      return  tCaption
	      end if
	    end if
	    # we don't parse any other type of post for a caption for an  image... it's too complicated and variable.
end parseForCaption

function parseForStory pContent
		If pContent contains "var data" then # dig for the <p> section at the end it could be empty.. that's OK
	      put	 (offset ("<p>",pContent) + 3) into tStartText
	       put	 (offset ("</p>",pContent)-1) into tEndText
	      put char tStartText to tEndText of pContent into tStory
	      put word 1 to 60 of tStory into tStory
	      put "..." after tStory
	      return  tStory
	      else # assume this is a iPhone Apps WP post and it is plain HTML with breaks and tags
	         replace "=" with cr in pContent
			   replace "alt" with cr in pContent
			   replace "<br" with (cr &"<br") in pContent
			   replace "<br /" with "" in pContent
			   replace ">" with cr in pContent
   			   replace quote with "" in pContent
			   repeat for each line x in pContent
					if (x contains ".jpg") then next repeat	
					if (x contains "/") then next repeat	
					if (x contains "class") then next repeat	
					if (x contains "<") then next repeat						
			      put x & cr after tText
			   end repeat
			   repeat for each line y in tText 
			      if len(y) > 3 then put y & " " after tStory
			   end repeat
			       return tStory
	     end if
end parseForStory

function wpGetLastPosts pBlogID, pUser, pPassword
	put wpGetPosts(sWordpressBlogID, sWordpressUsername,sWordpressPassword) into tA
	put the keys of tA["methodResponse"]["params"]["param"]["value"]["array"]["data"] into tList
	replace "value[" with empty in tList
	replace "]" with empty in tList
	sort tList
	repeat for each line k in tList
		put "value["&k&"]" into tPost
		put tA["methodResponse"]["params"]["param"]["value"]["array"]["data"][tPost]["struct"]["member[16]"]["value"]["string"] into tRetValA[k]["link"]
		put tA["methodResponse"]["params"]["param"]["value"]["array"]["data"][tPost]["struct"]["member[2]"]["value"]["string"] into tRetValA[k]["title"]
		put tA["methodResponse"]["params"]["param"]["value"]["array"]["data"][tPost]["struct"]["member[13]"]["value"]["string"] into pContent
		--put parseContent(pContent) into tRetValA[k]["content"]
		put parseForImage(pContent) into tRetValA[k]["image"]
		put parseForCaption(pContent) into tRetValA[k]["caption"]
		put parseForStory(pContent) into tRetValA[k]["story"]
		put tA["methodResponse"]["params"]["param"]["value"]["array"]["data"][tPost]["struct"]["member[3]"]["value"]["dateTime.iso8601"] into tTemp
		put char 1 to 4 of tTemp into tYear
		put char 5 to 6 of tTemp into tMonth
		put char 7 to 8 of tTemp into tDate
		put (tYear & "-" & tMonth & "-" & tDate) into tRetValA[k]["timestamp"]
		get (tYear , tMonth , tDate,0,0,0,0)
		convert it to long internet date
		put word 1 to 4 of it into tRetValA[k]["date"]
	end repeat
	--logArrayData tRetValA
	return tRetValA
end wpGetLastPosts


	
		