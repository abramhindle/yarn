#!/usr/bin/perl
#GPL Version 2 
#(C) 2007 Abram Hindle
use strict;
open(my $fd,"goodtimes.data");
my @goodtimes = <$fd>;
close($fd);
chomp foreach @goodtimes;

open(my $fd,"badtimes.data");
my @badtimes = <$fd>;
close($fd);
chomp foreach @badtimes;
my %dist = ();
sub dist { return abs($_[1] - $_[0]); }
foreach my $time (@badtimes) {
	my $min = dist($time,$goodtimes[0]);
	$dist{$time} = $min;
	foreach my $gtime (@goodtimes) {
		my $pmin = dist($time , $gtime);
		if ($pmin < $min) {
			$min = $pmin;
		}
	}
	$dist{$time} = $min;
}
my $max = 0;
foreach my $time (@badtimes) {
	if ($dist{$time} > $max) {
		$max = $dist{$time};
	}
}
foreach my $time (@badtimes) {
	print getTime($time)." ".(1.0-$dist{$time}/$max),$/;
}
sub getTime {
	my @a = localtime($_[0]); 
	$a[5]+=1900; 
	$a[4]++; 
	return join("-",@a[5,4,3]);
}
