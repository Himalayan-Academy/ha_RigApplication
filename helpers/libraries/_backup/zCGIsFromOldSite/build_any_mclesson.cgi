#!/opt/web/bin/revolution -ui

# This is a modification of the CGI that builds the daily lesson at midnight. 
# The latter based on the lesson one being pegged to April 13th. 
# This CGI uses input from the URL, which passes the lesson number to the CGI
# TBD: (because I don't know what I'm doing as of today, but theoretically:)
# The lesson number is either input by the user from from the web page itself
# or we get the lesson number from the cookie and update the lesson by one 
# July 13, 2010, Sivakatirswami


on startup

# Name-value pair is a valid daily lesson request
# ["lesson"=[any integer between 1-365]]

put $QUERY_STRING  into tQuery
put urlDecode(tQuery)  into tQuery
split tQuery by ";" and "="
put tQuery["lesson"] into tLessonNo



  set the defaultfolder to "/home/himalayan/public_html/study/mc/daily_lesson_source/"


  -- First we load our template files

  put url "file:my_mc_lesson_head.txt" into tHead
  put url "file:my_mc_lesson_lead.txt" into tLead
  put url "file:my_mc_lesson_body.txt" into tBody
  
  -- Next we load our source texts
  put url "file:dws-final.txt" into tDwS
  put url "file:lws-final.txt" into tLwS
  put url "file:sutras-final.txt" into tSutras
  put url "file:mws-final.txt" into tMwS
  
if tLessonNo > 365 then

     # inform the user to try again
   put "<h3>Sorry, you must enter a number between 1 and 365. <br /> Click the back button in your browser and try again.</h3>" into buffer

    else

  
#put 322 into tLessonNo

  ---create the lesson of the day 
  put tHead into tempHead
    put tBody into tempBody
  
    --Now make insertions into  the head
 replace "<###tDate###>" with "My Current Lesson: " in tempHead
    replace "<###tLessonNo###>" with tLessonNo in tempHead
    replace "<###tLessonNo###>" with tLessonNo in tempBody
    
    ---Next get the today's text from all five source files
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
   -- replace cr with "<br />" in item 3 of tLwSLesson
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
   -- replace cr with "<br />" in item 3 of tMwSLesson
    replace "<### MwS Lesson ###>" with (item 3 of tMwSLesson) in tempBody

  --build the lesson

    put tempHead & cr & tempBody into tWholeLesson
   put tWholeLesson  into url ("file:../my_lesson.shtml")
   put tWholeLesson into buffer

end if

    put "Content-Type: text/html" & cr
    put "Content-Length:" && the length of buffer & cr & cr
    put buffer 

end startup

    