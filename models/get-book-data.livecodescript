script "get-book-data"

# this model gets information from the database for display of a single book
# for now we are hard coding the data here while the database is under development

--| Security handler to block direct access
put gRigA["BASEPATH"] into gRigA["BASEPATH"]

if gRigA["BASEPATH"] is "gRigA["BASEPATH"]" then
    put "No direct script access allowed."
    exit to top
end if
----------------------------------------------

function findBookByArray pA
	rigDbWhere pA
	combine pA by "," and "="
	rigLogMessage "debug", "looking for book:" && pA
	put rigDbGet("item") into tQuery
	if tQuery["numrows"] > 0 then
		repeat with x = 1 to tQuery["numrows"]
			put rigDbRow(x) into tRetA[x]
			if tRetA[x]["cover"] is empty then
				if there is a file ($_SERVER["document_root"]& "/books/" & tRetA[x]["file_id"] & "/" &tRetA[x]["file_id"] & "_cover.jpg") then
					put ("http://" & $_SERVER["SERVER_NAME"] & "/books/" & tRetA[x]["file_id"] & "/" &tRetA[x]["file_id"] & "_cover.jpg") into tRetA[x]["cover"]
				else
					put empty into tRetA[x]["cover"]
				end if
			end if
			-- get the channels of distribution (mainly print version)
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("channel") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["channels"][y]
				end repeat
			end if
			-- get the available formats
			rigDbWhere "item_id", tRetA[x]["item_id"]
			put rigDbGet("item_format") into tChannelQuery
			if tChannelQuery["numrows"] > 0 then
				repeat with y = 1 to tChannelQuery["numrows"]
						put rigDbRow(y) into tRetA[x]["formats"][y]
				end repeat
			end if
			-- go back to the book query
			put rigDbGet("item") into tQuery
		end repeat
	  return tRetA
	else
		return false
	end if
end findBookByArray

function getBookFormat pA, pFormat
	repeat for each key tK in pA["formats"]
		if  pA["formats"][tK]["format_name"] is pFormat then
			return pA["formats"][tK]
		end if
	end repeat
	return empty
end getBookFormat

function folderForBook pB
		
		return ($_SERVER["DOCUMENT_ROOT"] & "/media/books/" & pB["file_id"]) 
end folderForBook
	


function getDescription
return "There are always on the Earth a few rare souls who from birth are open to the mysteries within life and consciousness more than the rest of us. They become the medicine men, the shamans, the mystic hermits, the spiritual visionaries and awakeners.  In <i>Gurudeva's Spiritual Visions,</i> his successor, Bodhinatha, shares 14 of his master's inner experiences. From the day he was born in Oakland, California, Satguru Sivaya Subramuniyaswami was different.</br /></br />Oh, he went to school, played in the mountain snows where he was raised, near Lake Tahoe, danced his heart out and became the Premier Danseur of the San Francisco Ballet Company at nineteen. But those day-to-day exploits did not define him. He was defined by the inner experiences he had from the beginning to the end of his life. Amazingly, these visions began as he lay in a crib, a mere infant, as you will read on the following pages. <br /><br /> In this book we share twelve of those visions, and we let Gurudeva's own words, when we have them, tell the tale. Each is different, with hardly anything to connect it to another, as though he were opening doors to complete worlds of knowledge, experience, divinity. </br /></br />It is a jewel of a book, exquisitely written, designed and illustrated with vintage early photos of Gurudeva, S. Rajam's delicate watercolors and esoteric motifs by Gurudeva himself."
	end getDescription

function getPromoBlurb

	return "Share in the mystical experiences and visions of the founder of Hinduism Today magazine, Satguru Sivaya Subramuniyaswami (Gurudeva), who lived in constant communion with our great devas and Gods--and with his own superconscious faculties."

end getPromoBlurb


Function getBookData

# these will be database queries later on.
	
	put rigImageAsset("books/grvisions_cover-thumb.jpg",,,TRUE) into gBookData["bookCover"]   
	
	put "Gurudeva's Spiritual Visions" into gBookData["bookTitle"]
	
	put "Twelve Encounters With Worlds Within" into gBookData["bookSubTitle"]
	
	put "Satguru Bodhinatha Veylanswami" into gBookData["author"]
	
	put "metaphysics, clairvoyance, clairaudience, visions, God, Gods, superconsciousness" into gBookData["categories"]
	
	put "e-book, print, web" into gBookData["formats"]
	
put format ("<a href=\"http://www.minimela.com/index.php?main_page=product_info&cPath=106&products_id=640\"> Minimela</a> | <a href=\"http://www.amazon.com/Gurudevas-Spiritual-Visions-ebook/dp/B003ZSHPGQ/ref=sr_1_1?ie=UTF8&m=AG56TWVU5XWC2&s=books&qid=1301345937&sr=8-1\"> Amazon </a>| <a href=\"http://itunes.apple.com/us/book/gurudevas-spiritual-visions/id387656180?ls=1\">iTunes </a> " ) into gBookData["channels"]
	
	put getPromoBlurb () into gBookData["promoBlurb"]
	
	put getDescription () into gBookData["bookDescription"]
	
	put "" into gBookData["bookReaderComments"]
	
	put "978-1-934145-05-0" into gBookData["isbn"]
	
	put "softcover, ring bound, 94 pages" into gBookData["productDetail"]
	
	return gBookData

end getBookData