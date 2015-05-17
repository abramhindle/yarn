#!/usr/bin/perl
# (c) 2007 Abram Hindle
# GPL Version 2 or greater
use strict;
use Math::Trig;
use SWF qw(:ALL);
SWF::setScale(1.0);


my $m = new SWF::Movie();
#$m->setDimension(1024*10, 768*10);
$m->setDimension(6000,4000);
$m->setBackground(0xff, 0xff, 0xff);
sub simpleLine {
	my ($m,$x1,$y1,$x2,$y2) = @_;
	my $xd = ($x2-$x1);
	my $yd = ($y2-$y1);
	my $len = sqrt($yd*$yd + $xd*$xd);
	my $shape = new SWF::Shape();
	$shape->setLine(0, 0, 0, 0);
	$shape->movePenTo(0,0);
	$shape->drawLine($len,0);
	my $i = $m->add($shape);
	my $degrees = rad2deg(acos($yd/$len));
	if ($xd > 0) {
		$degrees+=270;
	} else {
		if ($yd > 0) { #quad 2
			$degrees+=180;
		}
	}
	$i->moveTo($x1,$y1);
	$i->rotate($degrees);
	return $i;
}
my $cx = 2000;
my $cy = 2000;
	my $nl = simpleLine($m,$cx,$cy,4000,4000);
	my $nl = simpleLine($m,$cx,$cy,-4000,4000);
#                |
#                | 
#       3        |         4
#                |
#                |
#  --------------------------------
#                |
#                |
#      2         |        1
#                |
#                |

for my $w (1..360) {
	
	#quadrant 1 = black
	my $nl = simpleLine($m,$cx,$cy,4000,$cy+(4000-$cy)*$w/100);
	$nl->addColor(0x00,0x0,0x0);
	my $nl = simpleLine($m,$cy,$cx,$cx + (4000-$cx)*$w/100,4000);
	$nl->addColor(0x0,0x0,0x0);
	#quadrant 4 = grey
	my $nl = simpleLine($m,$cx,$cy,4000,$cy-(4000-$cy)*$w/100);
	$nl->addColor(0xaa,0xaa,0xaa);
	my $nl = simpleLine($m,$cy,$cx,$cx + (4000-$cx)*$w/100,-4000);
	$nl->addColor(0xaa,0xaa,0xaa);
	##quadrant 3
	my $nl = simpleLine($m,$cy,$cx,$cx - (4000-$cx)*$w/100,-4000);
	$nl->addColor(0xaa,0xCC,0xFF);
	my $nl = simpleLine($m,$cx,$cy,-4000,$cy-(4000-$cy)*$w/100);
	$nl->addColor(0xaa,0xCC,0xFF);
	##quadrant 2
	my $nl = simpleLine($m,$cy,$cx,$cx - (4000-$cx)*$w/100,4000);
	$nl->addColor(0xFF,0xCC,0xaa);
	my $nl = simpleLine($m,$cx,$cy,-4000,$cy+(4000-$cy)*$w/100);
	$nl->addColor(0xFF,0xCC,0xaa);
	$m->nextFrame();
}
for my $w (1..100) {
	#my $nl = simpleLine($m,1000,1000,2000,1000+2*$w);
	#my $nl = simpleLine($m,1000,1000,2000,1000-2*$w);
	#my $nl = getLine($m,1000,1000,2000,1000+2*$w);
	#$nl = getLine($m,1000,1000,2000,1000-2*$w);

	#$nl = getLine($m,1,1000-2*$w,1000,1000);
	#$nl->addColor(0xff,0x0,0x0);
	#$nl = getLine($m,1,1000+2*$w,1000,1000);
	#$nl->addColor(0x0,0xff,0x0);
	##my $nl = getline($m,1000,1000,0,1000+2*$w);
	##my $nl = getline($m,1000,1000,0,1000-2*$w);
	##my $nl = getLine($m,0,1000,-1000,1000+2*$w);
	#$m->nextFrame();
}

$m->save("lines.swf");
