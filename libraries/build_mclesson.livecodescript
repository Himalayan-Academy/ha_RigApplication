script "build_mclesson"

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
        rigLogMessage "debug", "Build MClesson Library Loaded"
      end if
      
      # SET INITIAL VALUES OF THE LIBRARY VARIABLES
      -- _rigSetDefaultValues ---------------------- rabit
      #
    end if -- if sStackInUse <> TRUE
    
  else
    pass libraryStack
  end if -- if the short name of the target = the short name of me
end libraryStack

---------------------------- rabit
# Run initial configuration procedures. Don't remove, even if it does nothing!
command rigRunInitialbuild_mclessonConfig pConfig

end rigRunInitialbuild_mclessonConfig
-----------------------------




global gData
local tMCLessonFolder

function makeDailyLesson pLessonNumber
	# LOGGING
	rigLogMessage "MCDAILYLESSON", ("MC Daily Lesson Library Loaded" && pLessonNumber)
	
	
	# update  Master Course Lesson
	
	put $_SERVER["DOCUMENT_ROOT"] & "/html/livespiritually/become-student/mc-daily_lesson_source" into tMCLessonFolder
	
	set the defaultfolder to tMCLessonFolder
	
	
	  put url "file:mc_lesson_head.txt" into tHead
	  put url "file:mc_lesson_lead.txt" into tLead
	  put url "file:mc_lesson_body.txt" into tBody

	  put tHead into tempHead
	  put tBody into tempBody
	  
	  -- Next we load our source texts
	  put url "file:dws-final.txt" into tDwS
	  put url "file:lws-final.txt" into tLwS
	  put url "file:sutras-final.txt" into tSutras
	  put url "file:mws-final.txt" into tMwS
	  

	  if (pLessonNumber ="FALSE") OR (pLessonNumber is empty) then
	  	# note that we should need the second clause, but the input library was
	  	# customized by Andre... and so it stopped returning "FALSE"
	  	# instead... it is just empty... same thing... 
	    # no value was posted so a query for post variable in the controller returns "FALSE"
	    # this is the daily lesson and not a request for a specific lesson number
  
	  --Next we get todays date items
	  put the long date into tToday
	  put item 3 of tToday into tYear
	  put word 1 of item 2 of tToday into tMonth
	  put word 2 of item 2 of tToday into tDay
	  if tDay is in (1,2,3,4,5,6,7,8,9) then put "0" before tDay
	  put tMonth & " " & tDay & ", " & tYear into tDate


	  # next we have to determine the correct Tamil New Year to count from
	  # this is tricky because from Jan-Feb-Mar-Apr 1-12: we have to use last year's date
	
	# set some base values for the algorithm to rollover automatically
	put "4/13/" into tStartYear
	put the date into tToday
	put tToday into theNow
	convert theNow to seconds
	set the itemdel to "/"

	if item 1 of tToday < 4 then # we are in the months of 1,2,3 Jan, Feb March
		  put (item 3 of tToday-1)  after tStartYear  # Still counting from last April
	  end if  

	  if item 1 of tToday = 4 then 
		  # we are in April and keep counting from last April until the 13th
		  # the only way is to check is on the seconds
		  put tStartYear into tNewYear
		 put item 3 of tToday after tNewYear  # this is the April 13 of this year....
		 convert tNewYear to seconds
		 if theNow < tNewYear then # we are i the period of April 1-12 and retain last year's start year
			  put (item 3 of tToday-1)  after tStartYear  
		  else  # this is April 13-30th 
			  put (item 3 of tToday)  after tStartYear
                              end if
	  end if  
	  if item 1 of tToday > 4  then
		  # we are in the period from May thru December and count from April of the current year
		 put (item 3 of tToday)  after tStartYear
	 end if


 -- Next we get the integer of the day of the year since April 13th
	  
	  #  In order to find the integer we need for today's lesson, we use the
	# rule that lesson one starts on the first day of the Hindu year, which
	# is generally about April 13, but could vary every year, so we have that
	# date hard coded and have to change it each year, and put the correct
	# day and year. Later we may find a way to get this from the system...
	#  
	# We then take advantage of the fact that Unix dates are stored as a number
	# of seconds from some base offset year (like 1970), and we convert both
	# today's date, and the new year date to seconds, and subtract, then divide
	#  by the number of seconds (86,000 = 24*60*60) in a day, to get the number
	# of days we are past the new year (= lesson number). However, we found
	# out, this only works when we sample the date after twelve noon.
	# 
	# When our cron job runs anytime before twelve noon (which it does) then
	# the difference between the seconds at midnite (which is the default moment
	# for the "generic" conversion of a date to seconds) and the seconds on the
	# machine when we query for the seconds integer "now", divided by 86,000
	# (the number of seconds in a day) the result will always be an integer,
	# plus a decimal fraction below .5 (probably around .3 on april 13, 1.3
	# on April 14, 2.3 on april 15 etc.) which is 1 integer off after round
	# because, being below .5, it rounds down (to 0 on April 13, 1 on april
	# 14 etc.) so we add 1 to make it (1 on april 13, 2 on april 14)
	convert tStartYear to seconds
	
	  put  (the round of ((theNow-tStartYear)/(24*60*60)))+ 1 into tLessonNo
	      # we want the date to appear in this case only
	   replace "<!--###tDate### -- >" with (tDate & " - Lesson " & tLessonNo) in tempHead
	  else
	
	  # the user is requesting a specific lesson
	  # we only display the lesson # he request and no date	  
	   replace "<!--###tDate### -- >" with ("Lesson " & pLessonNumber) in tempHead
	   put pLessonNumber into tLessonNo
	  
end if

rigLogMessage "Daily Lesson number", tLessonNo
	
	  ---create the lesson of the day 

	    replace "<###tLessonNo###>" with tLessonNo in tempBody
	    
	    ---Next get the todays text from all five source files
	    --and process and insert into the body
	
	    replace "<### Lesson Lead ###>" with tLead in tempBody
	    
	    set the itemdel to "%"
	    
	    --extracts from Dancing with Siva
	    --We also have to deal with DwS rotating 155 slokas for the internet
	    put tLessonNo into tDwSNo
	    if tDwSNo > 155 and tDwSNo < 311 then
	      put (tDwSNo-155) into  tDwSNo
	    else
	      if tDwSNo > 310  then
	        put (tDwSNo-310) into  tDwSNo
	      end if
	    end if
	    replace "<###tDwSNo###>" with tDwSNo in tempBody
	    
	    put item tDwSNo of tDwS into tDwSLesson
	    set the itemdel to "|"
	    replace "<### Sloka Title ###>" with (item 2 of tDwSLesson) in tempBody
	    replace "<### The Sloka ###>" with (item 3 of tDwSLesson) in tempBody
	    replace "<### The Bhasya ###>" with (item 5 of tDwSLesson) in tempBody
	    
	    --extracts from Living with Siva
	    set the itemdel to "%"
	    put item tLessonNo of tLwS into tLwSLesson
	    set the itemdel to "|"
	    replace "<### LwS Title ###>" with (item 2 of tLwSLesson) in tempBody
	   replace cr with "<br />" in item 3 of tLwSLesson
	    replace "<### LwS Lesson ###>" with (item 3 of tLwSLesson) in tempBody
	    
	    --extracts from the Sutras
	    set the itemdel to "%"
	    put item tLessonNo of tSutras into tSutraToday
	    set the itemdel to "|"
	    replace "<### Sutra Header ###>" with (item 2 of tSutraToday) in tempBody
	    replace "<### The Sutra  ###>" with (item 3 of tSutraToday) in tempBody
	    
	    --extracts from Merging with Siva
	    set the itemdel to "%"
	    put item tLessonNo of tMwS into tMwSLesson
	    set the itemdel to "|"
	    replace "<### MwS Title ###>" with (item 2 of tMwSLesson) in tempBody
	    replace cr with "<br />" in item 3 of tMwSLesson
	    replace "<### MwS Lesson ###>" with (item 3 of tMwSLesson) in tempBody
	
	  --build the lesson
	
	put tempHead & cr & tempBody  into tWholeLesson
	
	  
	  # Load sidebar ahead of time here
	     put ($_SERVER["DOCUMENT_ROOT"] & "/html/livespiritually/become-student/become-student-sidebar.html") into tDailyLessonSideBar
	     put url ("file:" & tDailyLessonSideBar)  into  gData["sideBar"]
	
	  return tWholeLesson
	  
end makeDailyLesson

    