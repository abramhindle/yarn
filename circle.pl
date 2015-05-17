#!/usr/bin/perl
#(C) 2007 Abram Hindle
#License: GPL V2 Or Later
use strict;
use Math::Trig;
use SWF qw(:ALL);
SWF::setScale(1.0);


my $m = new SWF::Movie();
$m->setRate(100);
#$m->setDimension(1024*10, 768*10);
$m->setDimension(6000,4000);
$m->setBackground(0xff, 0xff, 0xff);
sub simpleLine {
	my ($m,$x1,$y1,$x2,$y2) = @_;
	my $xd = ($x2-$x1);
	my $yd = ($y2-$y1);
	my $len = sqrt($yd*$yd + $xd*$xd);
	my $shape = new SWF::Shape();
	$shape->setLeftFill($shape->addFill(0xff, 0, 0xff));
	$shape->setLine(0, 0, 0, 0);
	$shape->movePenTo(0,0);
	$shape->drawLine(0,1);
	$shape->drawLine($len,0);
	$shape->drawLine(0,-2);
	$shape->drawLine(-$len,0);
	$shape->drawLine(0,1);
	my $i = $m->add($shape);
	if ($len <= 0.000000001) { return $i; }
	my $degrees = rad2deg(acos($yd/$len));
	if ($xd > 0) {
		$degrees+=270;
	} else {
		$degrees = 270 - $degrees;
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
my $len = 1000;
my @arcs = ();
for my $w (0..360) {
	#cos degrees = a/h
	#sin degrees = o/h
	my $rad = deg2rad($w);
	my $adjacent =cos($rad)*$len; #x
	my $opposite =sin($rad)*$len; #y
	my $nl = simpleLine($m,$cx,$cy,$cx + $adjacent,$cy + $opposite);
	push @arcs,$nl;
	$nl->addColor(255*$w/360,128*$w/360,255*$w/360);
	$m->nextFrame();
}
foreach (@arcs) {
	$_->scale(2.0,40.0);
	$m->nextFrame();
}

$m->save("circle.swf");
