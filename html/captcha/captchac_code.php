<?php

// ----------------------------------------------------------------
// Captcha Creator PHP Image Displaying Script.
// Copyright (c) 2007 Alexandru Marias. All rights reserved
// Web: http://www.captchacreator.com
// Phone: +40722486348
// ----------------------------------------------------------------

// Define the characters that can make up the Turing string
// Mixed-case is apparently a bit of a problem,
// so lets pick one or the other

include_once('captchac_config.php'); // Security functions
include_once('captchac_lib.php'); // Security functions

session_start();

$turing = RandomCode($CMinSize,$CMaxSize);

// Put it in session
$_SESSION['turing_string'] = $turing;
                   
switch ($captcha_type) {
case 1:
    
if ($CFontUsed == 1 ) {
$i=0;
if ($handle = opendir($fonts_dir)) 
	{
    	while (false !== ($file = readdir($handle))) 
        	if ($file != "." && $file != "..") {
            	$fontl[$i] = $fonts_dir . '/' . $file;
		$i++;
        	}   
	closedir($handle);
    	}
$FontsNo=$i;

$fontno = mt_rand(0,$FontsNo-1);
$font = $fontl[$fontno];
}
	else $font = $CFontURL;
                 
/* initialize variables */

$length = strlen($turing);
$data = array();
$image_width = $image_height = 0;


/* build the data array of the characters, size, placement, etc. */

for($i=0; $i<$length; $i++) {

  $char = substr($turing, $i, 1);

  $size = mt_rand($CFontSizeMin, $CFontSizeMax);
  $angle = mt_rand($CFontRotMin, $CFontRotMax);

  $bbox = ImageTTFBBox( $size, $angle, $font, $char );

  $char_width = max($bbox[2], $bbox[4]) - min($bbox[0], $bbox[6]);
  $char_height = max($bbox[1], $bbox[3]) - min($bbox[7], $bbox[5]);

  $image_width += $char_width + $CFontPadding;
  $image_height = max($image_height, $char_height);

  $data[] = array(
    'char'    => $char,
    'size'    => $size,
    'angle'    => $angle,
    'height'  => $char_height,
    'width'    => $char_width,
  );
}

/* calculate the final image size, adding some padding */

$x_padding = 12;

if ( $CSize == 1 )
	{
	$image_width += ($x_padding * 2);
	$image_height = ($image_height * 1.5) + 2;
	}
   else {
	$image_width = $CSizeWidth;
	$image_height = $CSizeHeight;
	}


/* build the image, and allocte the colors */

$im = ImageCreate($image_width, $image_height);
$cs = mt_rand(1,3);

if ($CBackgroundType == 2)
	{
	$r = hexdec(substr($CBackgroundColor,1,2));
	$g = hexdec(substr($CBackgroundColor,3,2));
	$b = hexdec(substr($CBackgroundColor,5,2));
	}

else
	{

$d1 = $d2 = $d3 = 0;
while ( ($d1<50) AND ($d2<50) AND ($d3<50) )
	{
	$r = mt_rand(200,255);
	$g = mt_rand(200,255);
	$b = mt_rand(200,255);

	$d1 = abs($r-$g);
	$d2 = abs($r-$b);
	$d3 = abs($g-$b);
	}
	}

$color_bg    = ImageColorAllocate($im, $r, $g, $b );

$color_border  = ImageColorAllocate($im, round($r/2), round($g/2), round($b/2));

$color_line0  = ImageColorAllocate($im, round($r*0.85), round($g*0.85), round($b*0.85) );

$color_elipse0  = ImageColorAllocate($im, round($r*0.95), round($g*0.95), round($b*0.95) );
$color_elipse1  = ImageColorAllocate($im, round($r*0.90), round($g*0.90), round($b*0.90) );

	$d1 = mt_rand(0,50);
	$d2 = mt_rand(0,50);
	$d3 = mt_rand(0,50);

$color_line1  = ImageColorAllocate($im, $r-$d1, $g-$d2, $b-$d3 );

$d1 = $d2 = $d3 = 0;
while ( ($d1<100) AND ($d2<100) AND (d3<100) )
	{
	$r = mt_rand(0,150);
	$g = mt_rand(0,150);
	$b = mt_rand(0,150);

	$d1 = abs($r-$g);
	$d2 = abs($r-$b);
	$d3 = abs($g-$b);
	}

switch ( $CFontColorType ) 
	{
	case 1 : $color_text    = ImageColorAllocate($im, $r, $g, $b );
		break;
	case 2 : $color_text    = ImageColorAllocate($im, 0, 0, 0 );
		break;
	case 3 : $color_text    = ImageColorAllocate($im, 255, 255, 255 );
		break;
	case 4 : $color_text    = ImageColorAllocate($im, $color_text_r, $color_text_g, $color_text_b );
		break;
	}

$noiset = mt_rand(1,2);

if ( $CBackgroundType == 1 )
	{

switch ($noiset) {
	case '1' :
		/* make the random background elipses */
	for($l=0; $l<10; $l++) {

  		$c = 'color_elipse' . ($l%2);

		$cx = mt_rand(0, $image_width);
  		$cy = mt_rand(0, $image_width);
  		$rx = mt_rand(10, $image_width);
  		$ry = mt_rand(10, $image_width);

		ImageFilledEllipse($im, $cx, $cy, $rx, $ry, $$c );
  		}; break;
	case '2' :
		/* make the random background lines */
		for($l=0; $l<10; $l++) {

		$c = 'color_line' . ($l%2);

 	  	$lx = mt_rand(0, $image_width+$image_height);
  		$lw = mt_rand(0,3);
  		if ($lx > $image_width) {
    		  $lx -= $image_width;
    		  ImageFilledRectangle($im, 0, $lx, $image_width-1, $lx+$lw, $c );
  		   } else ImageFilledRectangle($im, $lx, 0, $lx+$lw, $image_height-1, $c );
  		}; break;
	} // end switch  

	}

if ( $CBackgroundType == 0 )
	{
  	$image_data=getimagesize($CBackgroundFile);

  	$image_type=$image_data[2];

  	if($image_type==1) $img_src=imagecreatefromgif($CBackgroundFile);
  	elseif($image_type==2) $img_src=imagecreatefromjpeg($CBackgroundFile);
  	elseif($image_type==3) $img_src=imagecreatefrompng($CBackgroundFile);

		if ( $CBackgroundFillType == 1 ) {
					  imagesettile($im,$img_src);
					  imagefill($im,0,0,IMG_COLOR_TILED);
					}
		else imagecopyresampled($im,$img_src,0,0,0,0,$image_width,$image_height,$image_data[0],$image_data[1]);
	
	}

/* output each character */

$pos_x = $x_padding + ($CFontPadding / 2);
foreach($data as $d) {

  $pos_y = ( ( $image_height + $d['height'] ) / 2 );
  ImageTTFText($im, $d['size'], $d['angle'], $pos_x, $pos_y, $color_text, $font, $d['char'] );

  $pos_x += $d['width'] + $CFontPadding;

}

/* a nice border */

ImageRectangle($im, 0, 0, $image_width-1, $image_height-1, $color_border);

/* display it */
  
switch ($output_type) {
 case 'jpeg':
  Header('Content-type: image/jpeg');
  ImageJPEG($im,NULL,100);
  break;

 case 'png':
 default:
  Header('Content-type: image/png');
  ImagePNG($im);
  break;
}
ImageDestroy($im);

break;

case 2:

break;

}

session_write_close();


 ?>
