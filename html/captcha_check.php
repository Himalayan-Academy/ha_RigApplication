<?php
	include('captcha/captchac_lib.php');   
	$Turing_code = $_GET["Turing"]; 
	if ( CheckCaptcha($Turing_code) == 0 )
    {
       echo "false";
    } else {
			 echo "true";
		}	

echo CheckCaptcha($Turing_code);
?>