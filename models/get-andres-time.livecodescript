script "get-andres-time"

# This library calculates everything for the report that appears on the Road Map Track Page
# We have some issues with ordering, month selection and fractional hours still mysterious


command getTimeReport



# The code here is first does generates the listings and then at the end
# we do a summary but on the page, the summary appears first.

# Attempt to get Current Month but this is not working
# only the Year query works so we get *all* of e.g. 2013 listed under "Current Month"

	rigDbWhere "YEAR(start_time) = YEAR(CURDATE())"
	# rigDbWhere "MONTH(start_time) = MONTH(CURDATE())" # NOT WORKING
	rigDbOrderBy "start_time" # NOT WORKING
	rigDbSelect "project, task, budget, start_time, description, TIMEDIFF(end_time, start_time) as amount", FALSE
	put rigDbGet("admin_time_tracker") into tQuery
	
	# because the query is bogus, we are not even using the gData payment array in the summary
	# instead we rely on the all-payment array below because this use all records
	# and failures in filtering are not then encountered.
	
	repeat with i = 1 to tQuery["numrows"]
		put rigDbRow(i) into tRow
		put tRow["budget"] into tBudget
		
		set the itemdel to ":"
		put item 1 of tRow["amount"] into tHour
		put item 2 of tRow["amount"] into tMinute
		put item 3 of tRow["amount"] into tSecond
		# convert everything to minutes
		add ((tSecond + (tMinute * 60) + (tHour * 60 * 60)) / 60) to gData["hoursdue"]["totals"][tBudget]
		put tRow into gData["hoursdue"]["entries"][i]
		
		# For a listing we just need to get the data out into a simple line-tab delimited variable 
		# to sort it properly the array keys are not sortable
		put tRow["start_time"] & tab into tTaskLine
		put tRow["task"]  & tab after tTaskLine
		put tRow["budget"]  & tab after tTaskLine
		put tRow["description"]  & tab after tTaskLine
		put tRow["budget"]  & tab after tTaskLine
		put tRow["amount"]   after tTaskLine
		# we are switching to line based delivery so we need to wipes CR's in the description now
		replace cr with " " in tTaskLine # one space
		put tTaskLine & cr after tLongReport
	end repeat
	 set the itemdel to tab
	 sort tLongReport descending by item 1 of each 	 
	 put tLongReport into gData["allTasksReport"]
	 
	 # will use the All Tasks report in the time-log view now that it 
	 
	# We query the database again , this time there is no "where" constraint. 
	# so we get all records
	
	rigDbOrderBy "start_time"
	rigDbSelect "project, task, budget, start_time, description, TIMEDIFF(end_time, start_time) as amount", FALSE
	put rigDbGet("admin_time_tracker") into tQuery
	repeat with i = 1 to tQuery["numrows"]
		put rigDbRow(i) into tRow
		put tRow["budget"] into tBudget
		
			set the itemdel to ":"
			put item 1 of tRow["amount"] into tHour
			put item 2 of tRow["amount"] into tMinute
			put item 3 of tRow["amount"] into tSecond
                         # convert everything minutes 
			add ((tSecond + (tMinute * 60) + (tHour * 60 * 60)) / 60) to gData["allHoursDue"]["totals"][tBudget]
			put tRow into gData["allHoursDue"]["entries"][i]
	end repeat
	
##### Everything that follows is all to get a summary report that appears at the top.

	# we now have an array with three keys for all totals:
	# gData["allHoursDue"]["totals"][tBudget]
	
# algorithm for the calculations:

# 1) get the total of time for HHE + GKWeb projects = work for DDD (Digital Dharma Drive)
#    and minimela separate variable.

repeat for each key tBudget in gData["allHoursDue"]["totals"]
 		if ( (tBudget = "GKWEB") or (tBudget= "HHE") ) then 
 		  add gData["allHoursDue"]["totals"][tBudget] to tDDDHours
 		 else
 		  add gData["allHoursDue"]["totals"][tBudget] to tMinimelaHours
 		end if
end repeat

# 2) get the total of payment sent for GKWEb only = payment for all DDD projects
#    and minimela separately

put rigDbGet("admin_time_payments") into tQuery

repeat with i = 1 to tQuery["numrows"]
		put rigDbRow(i) into tRow
		if ( (tRow["budget"] = "HHE") or (tRow["budget"] = "GKWeb") ) then
 			add ((tRow["hour"] * 60)) to tDDDPayments
 		else
 			add ((tRow["hour"] * 60)) to tMinimelaPayments
 		end if 	
 		
 	# extract a list of payments, so we can later sort and pull the last payment data
 	# get out of the array!
 	# to sort it properly the array keys are not sortable
		put tRow["date"] & tab into tPaymentLine
		put tRow["budget"]  & tab after tPaymentLine
		put tRow["hour"]  & tab after tPaymentLine
		put tRow["rate"]  & tab after tPaymentLine
		put tRow["comment"]  after tPaymentLine
		put tPaymentLine & cr after tPaymentReport
	
end repeat
    # see the time-log.lc view for how we present these data:
	 set the itemdel to tab
	 sort tPaymentReport descending by item 1 of each
	  put line 1 of tPaymentReport into tMostRecentPayment
	 put ( (item 3 of  tMostRecentPayment) * (item 4 of  tMostRecentPayment) ) into tPaymentAmount
	put tPaymentAmount into gData["mostRecentPayment"][1]
	put item 1 of tMostRecentPayment into gData["mostRecentPayment"][pDate]
	put item 2 of tMostRecentPayment into gData["mostRecentPayment"][pBudget]
	put item 3 of tMostRecentPayment into gData["mostRecentPayment"][pHours]
	put item 4 of tMostRecentPayment into gData["mostRecentPayment"][pRate]
	put item 5 of tMostRecentPayment into gData["mostRecentPayment"][pComment]
	 


# 3) subtract #1 from # 2 to get the hours due for "Digital Dharma Fund"
#    and the same for minimela

put (tDDDPayments - tDDDHours) into gData["DDDHoursDue"]
put (tMinimelaPayments - tMinimelaHours) into gData["MinimelaHoursDue"]

## Create a table/statement of Current Account

 if gData["DDDHoursDue"] < 0 then
 	      # oh hours due!!!
	   put "+" into tDDDPrefix
	   multiply gData["DDDHoursDue"] by -1
	 else
	   put "-" into tDDDPrefix
	 end if
	
	    put gData["DDDHoursDue"] div 60 into tDDDHours
	    # I think we haver hours as a decimal at this point.
	     put (tDDDHours * 40) into tDDDPaymentDue
	   
	   # not needed or wanted:
	   #put gData["DDDHoursDue"] mod 60 into tDDDMinutes   
	    # Add round ((40/60*tDDDMinutes),2) to tDDDPaymentDue
	    
     #	if the len of tMinutes is 1 then put 0 before tDDDMinutes
     	
     	#Set up data for the table output
     	
		 	put ("Digital Dharma")  into tData[1]{1]
		         put (tDDDPrefix& tDDDHours)  into tData[1]{2]
		
		# we are in decimals, I hope...no... something is wrong here our hourly fractions
		# are not calculated correctly.... anyway comes close enough full hours get paid.
		 # put (tDDDPrefix& tDDDHours &":" & tDDDMinutes)  into tData[1]{2]
			# We need to be working in decimal fractions of an  hour.
			# put (tDDDPrefix& tDDDHours &":" & tDDDMinutes)  into tData[1]{2]
          
          put "$40.00"  into tData[1]{3]
            put "$"& tDDDPaymentDue into tData[1]{4]

 if gData["MinimelaHoursDue"] < 0 then
 	      # oh hours due!!!
	   put "+" into tMiniPrefix
	   multiply gData["MinimelaHoursDue"] by -1
	 else
	   put "-" into tMiniPrefix
	 end if
	    put gData["MinimelaHoursDue"] div 60 into tMiniHours
	    put (tMiniHours *40) into tMinimelaPaymentDue
	    
	    #put gData["MinimelaHoursDue"] mod 60 into tMiniMinutes 
	   #Add round ((22.5/60*tMiniMinutes),2) to tMinimelaPaymentDue
	#if the len of tMinutes is 1 then put 0 before tMiniMinutes
	
	#Set up data for the table output
     	
		 	put "Minimela"  into tData[2]{1]
			put (tMiniPrefix & tMiniHours)  into tData[2]{2]
           
           put "$40"  into tData[2]{3]
            put "$"& tMinimelaPaymentDue  into tData[2]{4]
  
    # Get a total invoice into a separate line of the table 
    
        put "Total" into tData[3][1]
        put "&nbsp;" into tData[3][2]
          put "&nbsp;" into tData[3][3]
        put "$" & (tDDDPaymentDue +tMinimelaPaymentDue) into tData[3][4] 
        
     
        rigSetTableHeading "<b>Fund</b>,<b>Hours</b>,<b>Rate</b>,<b>Amount</b>"
		put format("<th align=\"left\">") into tTmpl["headingCellStart"]
		put format("<td align=\"right\">") into tTmpl["cellStart"]
			put format("<td align=\"right\">") into tTmpl["cellAltStart"]
		put "<table border=" & quote & "1" & quote && "class=" & quote &"table-standard" & quote && "cellpadding=" & quote & "6" & quote && "cellspacing=" & quote & "0" & quote & ">" into tTmpl["tableOpen"]		
		rigSetTableTemplate tTmpl 	
	    put rigGenerateTable(tData) into gData["currentAccount"]

	 
end getTimeReport


######## Old Report

# command getTimeReport
# 	rigDbWhere "MONTH(start_time) = MONTH(CURDATE())"
# 	rigDbOrderBy "start_time"
# 	rigDbSelect "project, task, budget, start_time, description, TIMEDIFF(end_time, start_time) as amount", FALSE
# 	put rigDbGet("admin_time_tracker") into tQuery
# 	repeat with i = 1 to tQuery["numrows"]
# 		put rigDbRow(i) into tRow
# 		put tRow["budget"] into tBudget
# 		
# 		set the itemdel to ":"
# 		put item 1 of tRow["amount"] into tHour
# 		put item 2 of tRow["amount"] into tMinute
# 		put item 3 of tRow["amount"] into tSecond
# 		
# 		add ((tSecond + (tMinute * 60) + (tHour * 60 * 60)) / 60) to gData["payment"]["totals"][tBudget]
# 		put tRow into gData["payment"]["entries"][i]
# 	end repeat
# 	rigDbOrderBy "start_time"
# 	rigDbSelect "project, task, budget, start_time, description, TIMEDIFF(end_time, start_time) as amount", FALSE
# 	put rigDbGet("admin_time_tracker") into tQuery
# 	repeat with i = 1 to tQuery["numrows"]
# 		put rigDbRow(i) into tRow
# 		put tRow["budget"] into tBudget
# 		
# 			set the itemdel to ":"
# 			put item 1 of tRow["amount"] into tHour
# 			put item 2 of tRow["amount"] into tMinute
# 			put item 3 of tRow["amount"] into tSecond
# 
# 			add ((tSecond + (tMinute * 60) + (tHour * 60 * 60)) / 60) to gData["all payments"]["totals"][tBudget]
# 			put tRow into gData["all payments"]["entries"][i]
# 	end repeat
# 	
# 	
# 	# we now have an array with three keys for all totals:
# 	# gData["all payments"]["totals"][tBudget]
# 	
# # algorithm for the calculations:
# 
# # 1) get the total of time for HHE + GKWeb projects = work for DDD (Digital Dharma Drive)
# #    and minimela separate variable.
# 
# repeat for each key tBudget in gData["all payments"]["totals"]
#  		if ( (tBudget = "GKWEB") or (tBudget= "HHE") ) then 
#  		  add gData["all payments"]["totals"][tBudget] to tDDDHours
#  		 else
#  		  add gData["all payments"]["totals"][tBudget] to tMinimelaHours
#  		end if
# end repeat
# 
# # 2) get the total of advance payments for GKWEb only = payment for all DDD projects
# #    and minimela separately
# 
# put rigDbGet("admin_time_payments") into tQuery
# 
# repeat with i = 1 to tQuery["numrows"]
# 		put rigDbRow(i) into tRow
# 		if ( (tRow["budget"] = "HHE") or (tRow["budget"] = "GKWeb") ) then
#  			add ((tRow["hour"] * 60)) to tDDDPayments
#  		else
#  			add ((tRow["hour"] * 60)) to tMinimelaPayments
#  		end if 		
# end repeat
# 
# 
# # 3) subtract #1 from # 2 to get the hours due for "Digital Dharma Fund"
# #    and the same for minimela
# 
# put (tDDDPayments - tDDDHours) into gData["DDDHoursDue"]
# put (tMinimelaPayments - tMinimelaHours) into gData["MinimelaHoursDue"]
# 
# 	 
# end getTimeReport
