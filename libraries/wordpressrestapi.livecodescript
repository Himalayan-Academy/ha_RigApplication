script "wordpressrestapi"

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
        rigLogMessage "debug", "Wordpress REST Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues --------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# LOGGING
-- rigLogMessage "debug", "Wordpress REST Library Loaded" ----------- rabit

# DECLARE LOCAL VARIABLES

# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig
command rigRunInitialWordpressRestAPIConfig
  --Run initial configuration procedures. Don't remove this handler, even if it does nothing.'
  rigLoaderLoadLibrary "json"
end rigRunInitialWordpressRestAPIConfig



## LOW LEVEL ROUTINES

function r_passwordChunk

      put "oC5frt3Z5JiyaSWAC7jGlpZr" into kAPP_PASSWORD
      put "admin" into kWP_USER
-- constant kAPI_URL = "https://www.himalayanacademy.com/blog/taka/wp-json/wp/v2"  -- v2 of WP REST API
   return the base64encode of (kWP_USER & ":" & kAPP_PASSWORD)

end r_passwordChunk

function r_makeUrl pURL
  put "https://www.himalayanacademy.com/blog/index.php?rest_route=/wp/v2" into kAPI_URL
   return kAPI_URL & pURL
end r_makeUrl

function r_api pMethod, pURL, pDataA
   set the httpheaders to "Authorization: Basic" && r_passwordChunk() & cr & "Content-Type: application/json"
   switch pMethod
      case "GET"
         put url r_makeUrl(pUrl) into tResponse
         put tResponse
         quit
         if the result is not empty then
            put "error" && the result && it
            rigLogMessage "error", "wperr:" && the result && it
            exit r_api
         end if
         return jsontoarray(tResponse)
         break
      case "POST"
         put arrayToJSON(pDataA) into tJson
         post tJson to url r_makeUrl(pUrl)
         if the result is not empty then
            put "error" && the result && it
            rigLogMessage "error", "wperr:" && the result && it
            exit r_api
         end if
         return jsontoarray(it)
         break
   end switch
end r_api

## HIGH-LEVEL ROUTINES
function r_wpGetPosts
   put r_api("GET", "/posts") into tPostsA
   return tPostsA
end r_wpGetPosts

function r_wpNewPost pNewPostA
   put r_api("POST", "/posts", pNewPostA) into tResponseA
   return tResponseA
end r_wpNewPost

function r_wpUpdatePost pID, pNewPostA
   if pID is not a number then
      return "WordpressAPIErr, Post ID is not a number. Can't update."
   end if
   put r_api("POST", "/posts/" & pID, pNewPostA) into tResponseA
   return tResponseA
end r_wpUpdatePost

function r_wpGetCategories
   put r_api("GET", "/categories&per_page=100") into tCategoriesA
   return tCategoriesA
end r_wpGetCategories

