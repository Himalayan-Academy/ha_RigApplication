script "getsetheadnav"

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
        rigLogMessage "debug", "Get Set Page Header and Navigation Loaded"
      end if
      
      
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack


# DECLARE GLOBAL VARIABLES
global gData


# DECLARE LOCAL VARIABLES	
local tPageHeader


# PROTOTYPE OF THE FOLLOWING HANDLER NAME: rigRunInitialLibrarynameConfig

command rigRunInitialGetsetheadnavConfig pConfig
    --Run initial configuration procedures. Dont remove this handler, even if it does nothing.
end rigRunInitialGetsetheadnavConfig

--> We get the page-header.lc view and set key elements
# Body Class must be set to call the proper CSS for the page
# The current navigation must be set to active
# the h2 page heading text must be set for the page we are on
# we could use gData vars, but we have to parse and poke the actual file
# so we use replacement strings instead in the view. 

function getRandomBanner
       
		put the defaultFolder into tCurrentFolder
		put $_SERVER["DOCUMENT_ROOT"] & "/assets/img/ddd-banners" into tBannersFolder
		
		set the defaultfolder to tBannersFolder
		put the files into tBanners	
		filter tBanners without ".*" 		 
		put  random(the number of lines of tBanners) into tNextBanner		
		put "/assets/img/ddd-banners/" & (line tNextBanner of tBanners) into gData["bannerPath"]  
		set the defaultFolder to tCurrentFolder
		
		# we will put the total also 
		
		put url ("https://donate.himalayanacademy.com/ddd/current-total.txt") into  gData["currentTotal"]
		
end getRandomBanner

function getSetHeadNav pBodyClass,pTitle,pActiveTopNav,pActiveSubNav


	# note the page heading here is not the title of the article, but a breadcrumb heading
	# it iterates as a headline site area we are in

	# To change the header globally, set up a different file in the views/sitewide folder and call it here..
	# e.g. "sitewide/page-header-ddd" for the Digital Dharma Header.

# uncomment the following line to turn on DDD banner images... 
# 1. getRandomBanner()
# 2. turn off  put mergeView ("sitewide/page-header") into tPageHeader
# 3. turn on  put mergeView ("sitewide/page-header-ddd") into tPageHeader
	
	get getRandomBanner()


        if pActiveSubNav = "removeBannerLogo" then 
            # we want to topics page "bare" at the top
            put mergeView ("sitewide/page-header-topics") into tPageHeader
      
      else
        # uncomment the following lines to turn on DDD banner images...   
	-- put mergeView ("sitewide/page-header") into tPageHeader
	   put mergeView ("sitewide/page-header-ddd") into tPageHeader 
	
	end if
	
	# LOGGING
	
-- rigLogMessage "debug", tPageHeader ------------ BR 

	# uncomment the following line to turn on DDD banner images... 
	# it calls the view which contains the <div> which holds the banner
	# then comment out when the drive is over and uncomment the one above

	


	replace "Body-Class" with pBodyClass in tPageHeader
	replace "Page-Heading-Title" with pTitle in tPageHeader
	put pTitle into gData["temp"]["title"]

	return tPageHeader 

end getSetHeadNav


	
		