#!/usr/bin/perl
# (C) 2007 Abram Hindle
# License: GPL V2 or Greater
use strict;
use Math::Trig;
use SWF qw(:ALL);
use XML::Parser;
use ModuleGraph;
use Math::Trig;
use Carp qw(confess);


my @vertice_outline_color = (200,200,200);
my @vertice_fill_color = (0x66, 0xff,0xaa);
my $file = (@ARGV && @ARGV[0] !~ /^\-/)?(shift @ARGV):"./histodiff.allornonedouble.graphs";
my ($colorInit,$colorGraph,$colorEdge) = (\&defaultColorInit,\&defaultGraphColor,\&defaultEdgeColor);
my $output_file = "test.swf";
my ($colorDecay,$filterDecay) = (undef,undef);
my $dfl_decay = 3;
while (@ARGV) {
	my $cur = shift @ARGV;
	if ($cur eq "-Cd") {
		($colorInit,$colorGraph,$colorEdge) = (\&defaultColorInit,\&defaultGraphColor,\&defaultEdgeColor);
	} elsif ($cur eq "-Ci") {
		($colorInit,$colorGraph,$colorEdge) = (\&importantColorInit,\&importantGraphColor,\&importantEdgeColor);
	} elsif ($cur eq "-decay") {
		$dfl_decay = shift @ARGV;
	} elsif ($cur eq "-Cdd") { #now with DECAY
		($colorInit,$colorGraph,$colorEdge) = (\&defaultColorInit,\&defaultGraphColor,\&defaultEdgeColor);
		($colorDecay,$filterDecay) = ( sub { return colorDecay($dfl_decay,defaultColorInit(),@_) }, sub { return filterDecay($dfl_decay,@_) } );
	} elsif ($cur eq "-Cid") { #now with DECAY
		($colorInit,$colorGraph,$colorEdge) = (\&importantColorInit,\&importantGraphColor,\&importantEdgeColor);
		($colorDecay,$filterDecay) = ( sub { return colorDecay($dfl_decay,importantColorInit(),@_) }, sub { return filterDecay($dfl_decay,@_) } );
	} elsif ($cur eq "-Chd") { #now with DECAY
		($colorInit,$colorGraph,$colorEdge) = (\&highlightColorInit,\&highlightGraphColor,\&highlightEdgeColor);
		($colorDecay,$filterDecay) = ( sub { return colorDecay($dfl_decay,highlightColorInit(),@_) }, sub { return filterDecay($dfl_decay,@_) } );
	} elsif ($cur eq "-o") {
		$output_file = shift @ARGV || $output_file;
	}
}

my $graphs = getGraphs( $file );
SWF::setVersion(6);
SWF::setScale(1.0);

my @boxes = (
#[qw(0    0    ROOT)],
[qw(1000 1000 BACKEND)],
[qw(1000 2000 DEVELOPERUTIL)],
[qw(1000 3000 EXECUTOR)],
[qw(1000 4000 INCLUDE)],
[qw(2000 1000 LIBPQ)],
[qw(2000 2000 OPTIMIZER)],
[qw(2000 3000 PARSER)],
[qw(2000 4000 QUERYEVALUATIONENGINE)],
[qw(3000 1000 REWRITER)],
[qw(3000 2000 STORAGEMANAGER)],
[qw(3000 3000 SYSTEMCONTROLMANAGER)],
[qw(3000 4000 TRAFFICCOP)],
[qw(4000 1000 UTIL)],
);
my @vertices = map {$_->[2]} @boxes;
#@boxes = map { $_->[0] = rand(4000); $_->[1] = rand(4000); $_} @boxes;
#radial layout
my $inc = 360.0/scalar(@boxes);
my $cx = 1600;
my $cy = 1600;
my $len = 1500;
my $cnt = 0;
foreach my $box (@boxes) {
	my $rad = deg2rad(45+$cnt*$inc);
	my $adjacent =cos($rad)*$len; #x
	my $opposite =sin($rad)*$len; #y
	$box->[0] = $cx + $adjacent;
	$box->[1] = $cy + $opposite;
	$cnt++;
}

my %coords = ();
foreach (@boxes) {
	my ($x,$y,$key) = @$_;
	$coords{$key} = [$x,$y];
}
my %edgeWeights = ();
my %edges = ();


my $m = new SWF::Movie();
$m->setDimension(4000, 4000);
$m->setBackground(0xff, 0xff, 0xff);

$m->setRate(100);


foreach my $a (@vertices) {
	foreach my $b (@vertices) {
		setWeight($a,$b,0);
		#my $edge = getEdge($m,$a,$b);
	}
}



my $font = new SWF::Font("./test.fdb");


{
	my @shapes;
	my @text;
	foreach my $a (@vertices) {
		my ($x,$y) = getCoords($a);
		checkCoords($x,$y,$a);
		my ($shape,$text) = getVertices($x,$y,$a);
		push @shapes, $m->add($shape);
		push @text, $m->add($text);
	}
	my $depth = 30000;
	$_->setDepth( $depth++  ) foreach (@shapes,@text);
	my $last;
	my ($cR,$cG,$cB) = &$colorInit();
	my $first = 1;
	my ($si,$st) = getText($m,"0",100,100);
	my ($ci,$ct) = getText($m,"0",100,200);
	my $progressbarbg = box($m,0,3800,4000,200,[0x00,0x00,0x00]);
	my $progressbar   = box($m,0,3800,4000,200,[0xFF,0x00,0x00]);
	$progressbarbg->setDepth($depth++);
	$progressbar->setDepth($depth++);
	$progressbar->setName("progressbar");
	$progressbarbg->setName("progressbarbg");
	$progressbar->scaleTo(0.1,1.0);
	my $buttonbox   = box(undef,0,3800,4000,200,[0x00,0xFF,0x00,0x00]);
	my (undef,$pawsbox)   = getText(undef,"Play",0,0);
	my (undef,$stepbox)   = getText(undef,"Paws",0,0);
#box(undef,0,0,200,200,[0x00,0xFF,0x00,0x00]);
	#my $stepbox   = box(undef,0,0,200,200,[0x00,0x00,0xFF,0x00]);

	my $sprite = new SWF::Sprite();
	my $pawsp  = new SWF::Sprite();
	my $stepsp = new SWF::Sprite();
	
	#sprite the navigation
	my $fl = $sprite->add($buttonbox);
	$sprite->nextFrame();
	my $bb = $m->add($sprite);
	$bb->moveTo(0,3800);
	$bb->setDepth($depth++);
	$bb->setName("boxcontrol");

	$pawsp->add($pawsbox);
	$pawsp->nextFrame();
	$bb = $m->add($pawsp);
	$bb->moveTo(3800,3600);
	$bb->setDepth($depth++);
	$bb->setName("pawscontrol");

	$stepsp->add($stepbox);
	$stepsp->nextFrame();
	$bb = $m->add($stepsp);
	$bb->moveTo(3500,3600);
	$bb->setDepth($depth++);
	$bb->setName("stepcontrol");

	my $cnt = 0;
	my $total = @$graphs;
	$m->add(new SWF::Action(" 
		boxcontrol.onRelease= function(){
			gotoAndStop(int((boxcontrol._xmouse/200.0) * $total ));
		};
		pawscontrol.onRelease= function(){
			play();
		};
		stepcontrol.onRelease= function(){
			nextFrame();
		};
	"
	));
	my %decay = ();
	foreach my $graph (@$graphs) {
		print $graph->getScore(). "\t";
		#warn "Graph! ".$graph->getScore();
		$progressbar->scaleTo($cnt/(1.0*$total),1.0);
		#$st->moveTo(0,0);
		#$st->addString($cnt);
		$m->remove($si);
		$m->remove($ci);
		($si,$st) = getText($m,$graph->getTime(),100,100);
		($ci,$ct) = getText($m,$cnt,100,200);
		($cR,$cG,$cB) = &$colorGraph($cR,$cG,$cB,
			score => $graph->getScore(),
		);
		#handle decay here
		if (defined $colorDecay) {
			%decay = &$filterDecay(%decay);
			while( my ($key,$val) = each %decay) {
				my @oldcolor = @{$val->{lastColor}};
				$val = &$colorDecay($val); #hash
				$decay{$key} = $val;
				my @color = @{$val->{lastColor}};
				if (listEqual(@color,@oldcolor)) {
					#warn "Not Decaying $key to @color from @oldcolor";
				} else {
					#warn "Decaying $key to @color";
					$val->{edge}->addColor(@color);
				}
			}
		}
		#
		foreach my $edge ($graph->getEdges()) {
			my ($a,$b,$w) = @$edge;
			#warn "EDGE $a $b $w";
			my $wo = getWeight($a,$b);
			if ($first || $w != $wo) {
				setWeight($a,$b,$w);
				if (updateEdge($m,$a,$b)) {
					#getEdge($m,$a,$b)->addColor($cR,$cG,$cB);
					my $edge = getEdge($m,$a,$b);
					my @color = &$colorEdge($cR,$cG,$cB);
					$edge->addColor(@color);
					if ($colorDecay) {
						$decay{edgeKey($a,$b)} = { #key is unimportant
							edge => $edge,
							lastColor => [ @color ],
							sinceChange => 0,
						};
					}
				}
			}
		}
		$m->nextFrame();
		$first = 0;
		$cnt++;
	}
	$m->remove($si);
	$m->remove($ci);
}



$m->save($output_file);


sub getGraphs {
	my $filename = shift;
	my $curr = ModuleGraph->new();
	my @graphs;
	my $graph = 0;
	my $score = 0;
	my $time = 0;
	my @char = ();
	my $start = sub {
		#(Expat, Element [, Attr, Val [,...]])
		my ($parser,$elm,%attr) = @_;
		if ($elm eq "arch") {
			 $curr = ModuleGraph->new();
			push @graphs,$curr;
		} elsif ($elm eq "graph") {
			$graph = 1;
			#warn "graph on!";
			@char = ();
		} elsif ($elm eq "score") {
			$score = 1;
		} elsif ($elm eq "time") {
			$time = 1;
		}
	};
	my $end = sub {
		my ($parser,$elm) = @_;
		if ($elm eq "graph") { 
			#warn "Graph Off!"; 
			$curr->unDump(join("",@char));
			$graph = 0; 
		}
		if ($elm eq "score") { $score = 0; }
		if ($elm eq "time") { $time = 0; }
	};
	my $char = sub {
		my ($parser,@res) = @_;
		if ($graph) {
			push @char, @res;
		}
		elsif ($score) {
			$curr->setScore(@res);
		}
		elsif ($time) {
			$curr->setTime(@res);
		}
	};
	my $parser = new XML::Parser( Handlers => {
			Start => $start,
			End   => $end,
			Char  => $char,
		}
	);
	eval {
		$parser->parsefile($filename);
	};
	if ($@) {
		warn "PARSER: $@";
	}
	return \@graphs;
}
sub getCoords {
	my ($a) = @_;
	if (exists $coords{$a}) {
		return @{$coords{$a}};
	} else {
		confess "[$a] doesn't have COORDS?";
		$coords{$a} = [0,0];
		return (0,0);
	}
}
sub getWeight {
	my ($a,$b) = @_;
	return $edgeWeights{$a}->{$b};
}
sub setWeight {
	my ($a,$b,$c) = @_;
	return $edgeWeights{$a}->{$b} = $c;
}
sub setEdge {
	my ($key1,$key2,$a) = @_;
	return $edges{$key1}->{$key2} = $a;
}
sub checkCoords {
	my ($x,$y,$key1) = @_;
	if (!defined($x) || !defined($y) || $x <= 0 || $y <= 0) { warn "[$key1] has zero coords"; }
	return ($x,$y);
}
sub getEdge {
	my ($m,$key1,$key2) = @_;
	if (!exists $edges{$key1}->{$key2} || !$edges{$key1}->{$key2}) {
		my ($x,$y) = getCoords($key1);
		my ($x2,$y2) = getCoords($key2);
		checkCoords($x,$y,$key1);
		checkCoords($x2,$y2,$key2);
		my $edge = getLine($m,$x,$y,$x2,$y2);
		$edges{$key1}->{$key2} = $edge;
	}
	return $edges{$key1}->{$key2};
}
sub weight {
	my ($w) = @_;
	return 0 if ($w < 0.5);
	my $res = log($w)*log($w)/(log(2)*log(2));
	return ($res < 1)?1:$res;
}
sub updateEdge {
	my ($m,$a,$b) = @_;
	my $w = 1;
	my $weight = getWeight($a,$b);
	if ($weight < 0.0001) {
		my $edge = getEdge($m,$a,$b);
		$m->remove($edge);
		setEdge($a,$b,undef);
		return 0;
	} else {
		getEdge($m,$a,$b)->scaleTo(1.0,weight($weight)*$w);
		return 1;
	}
}
sub getText {
	my ($m,$text,$x,$y,$height,$c) = @_;
	$height ||= 100;
	$c ||= [0,0,0];
	my $t = new SWF::Text();
	$t->setFont($font);
	$t->setColor(@$c);
	$t->setHeight($height);
	$t->addString($text);
	if (!defined $m) {
		return (undef,$t);
	}
	my $i = $m->add($t);
	$i->moveTo($x,$y);
	return ($i,$t);
}
#Adds a box with text at a location
sub getVertices {
	my ($x,$y,$text) = @_;
	my $shape = new SWF::Shape();
	my $t = new SWF::Text();
	$t->setFont($font);
	$t->moveTo($x, $y);
	$t->setColor(0, 0, 0);
	$t->setHeight(100);
	$t->addString($text);
	#$shape->setLine(40, 0x7f, 0, 0);
	$shape->setLine(40,@vertice_outline_color);
	#$shape->setLeftFill($shape->addFill(0xff, 0, 0xff,0xaa));
	$shape->setLeftFill($shape->addFill(0xff, @vertice_fill_color));
	$shape->movePenTo($x, $y);
	my $height = 100;
	my $width = $t->getWidth($text);
	$shape->drawLine($width,0);
	$shape->drawLine(0,-$height);
	$shape->drawLine(-$width,0);
	$shape->drawLine(0,$height);


	return ($shape,$t);
}
sub box {
	my ($m,$x1,$y1,$w,$h,$c) = @_;
	$c = $c || [0xff,0x00,0x00];
	my $shape = new SWF::Shape();
	$shape->setLeftFill($shape->addFill(@$c));
	$shape->setLine(0, 0, 0, 0);
	$shape->movePenTo(0,0);
	$shape->drawLine($w,0);
	$shape->drawLine(0,$h);
	$shape->drawLine(-$w,0);
	$shape->drawLine(0,-$h);
	if (defined $m) {
		my $i = $m->add($shape);
		$i->moveTo($x1,$y1);
		return $i;
	} else {
		return $shape;
	}
}
sub simpleLine {
	my ($m,$x1,$y1,$x2,$y2) = @_;
	my $xd = ($x2-$x1);
	my $yd = ($y2-$y1);
	my $len = sqrt($yd*$yd + $xd*$xd);
	my $shape = new SWF::Shape();
	$shape->setLeftFill($shape->addFill(0xcc, 0xcc, 0xcc,0xaa));
	$shape->setLine(0, 0, 0, 0);
	$shape->movePenTo(0,0);
	$shape->drawLine(0,1);
	$shape->drawLine($len*0.9,0);
	$shape->drawLine($len*0.1,-1);
	#$shape->drawLine(0,-2);
	$shape->drawLine(-$len*0.1,-1);
	$shape->drawLine(-$len*0.9,0);
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
sub getLine { return simpleLine(@_); }


sub defaultColorInit {
	return (64,191,192);
}
sub defaultGraphColor {
	my ($a,$b,$c) = @_;
	$a =  ($a+1)%256;
	$b =  ($b-1)%256;
	$c =  ($c+1)%256;
	return ($a,$b,$c);
}
sub colorIdentity {
	return @_;
}
sub defaultEdgeColor {
	return colorIdentity(@_);
}

sub importantColorInit {
	return (128,128,128);
}
sub importantGraphColor {
	my ($a,$b,$c,%hash) = @_;
	return (128,128,128) unless $hash{score};
	return (255,0,0) if $hash{score};
}
sub importantEdgeColor {
	return colorIdentity(@_);
}
sub highlightColorInit {
	return (128,128,128);
}
sub highlightGraphColor {
	my ($a,$b,$c,%hash) = @_;
	return (255,0,0);
}
sub highlightEdgeColor {
	return colorIdentity(@_);
}
sub edgeKey {
	return $_[0] . " -> ". $_[1];
}
sub colorDecay {
	my ($dfl_decay,$ia,$ib,$ic,$hash) = @_;
	my %nhash = %$hash;
	my ($a,$b,$c) = @{$nhash{lastColor}};
	my $since = $nhash{sinceChange};
	my $done = $since / (1.0 * $dfl_decay);
	$a = int( $ia * $done  + $a * ( 1 - $done ));
	$b = int( $ib * $done  + $b * ( 1 - $done ));
	$c = int( $ic * $done  + $c * ( 1 - $done ));
	$nhash{sinceChange} += 1;
	$nhash{lastColor} = [ $a , $b , $c ];
	return \%nhash;
}
sub filterDecay {
	my ($dfl_decay,%hash) = @_;
	my %out = ();
	while(my ($key,$val) = each %hash) {
		next if ($val->{sinceChange} > $dfl_decay);
		$out{$key} = $val;
	}
	return %out;
}
sub listEqual {
	my @list = @_;
	if ( scalar(@list) % 2 == 1 ) {
		return 0;
	}
	my $x = scalar(@list) / 2;
	for (my $i = 0 ; $i < $x; $i++) {
		my $a = $list[$i];
		my $b = $list[$x + $i];
		return 0 if $a != $b;
	}
	return 1;
}
sub listEqualTest {
	foreach my $code (
		"0",
		"listEqual(1,1)",
		"listEqual(1,1,1,1)",
		"listEqual(1,1,2,1)",
		"listEqual(1,1,1)",
		"listEqual(1,1,3,3,3)",
		"listEqual(4,4,4,4,4,4)",
		"listEqual(4,4,4,4,4,6)"
	) { 
		print $code,":",(eval $code),$/;
	}
	die;
}
