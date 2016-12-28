#!/opt/web/bin/revolution -ui

on startup
	start using stack "../public_html/resources/lexicon/lexicon.rev"
	put getRandomWord() into buffer
	  put "Content-Type: text/plain" & cr
  put "Content-Length:" && the length of buffer & cr & cr
  put buffer
end startup

